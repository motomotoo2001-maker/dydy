#!/usr/bin/env python3
import argparse, base64, json, os, sys
from pathlib import Path
from PIL import Image, ImageFilter, ImageDraw
import numpy as np

ANALYSIS_SIZE=(320,180)
THUMB_SIZE=(24,14)
IGNORE=[(0.0,0.0,0.40,0.16),(0.82,0.88,1.0,1.0)]
WEIGHTS={
    'brightness':0.12,'contrast':0.10,'saturation':0.08,'temperature':0.10,
    'palette':0.22,'edge_density':0.14,'coarse_structure':0.16,'perceptual_blur':0.08,
}

def load_rgb(path,size=ANALYSIS_SIZE):
    return Image.open(path).convert('RGB').resize(size,Image.Resampling.LANCZOS)

def valid_mask(size):
    w,h=size
    mask=np.ones((h,w),dtype=bool)
    for x0,y0,x1,y1 in IGNORE:
        mask[int(y0*h):int(y1*h),int(x0*w):int(x1*w)]=False
    return mask

def image_metrics(im):
    arr=np.asarray(im).astype(np.float32)/255.0
    mask=valid_mask(im.size)
    pix=arr[mask]
    lum=0.2126*pix[:,0]+0.7152*pix[:,1]+0.0722*pix[:,2]
    sat=pix.max(axis=1)-pix.min(axis=1)
    hist=[]
    for c in range(3):
        h,_=np.histogram(pix[:,c],bins=16,range=(0,1))
        h=h.astype(np.float64)
        h/=max(h.sum(),1.0)
        hist.extend(h.tolist())
    gray=np.asarray(im.convert('L').filter(ImageFilter.FIND_EDGES)).astype(np.float32)/255.0
    edge=float((gray[mask]>0.18).mean())
    coarse=np.asarray(im.convert('L').resize((8,5),Image.Resampling.BILINEAR)).astype(np.float32)/255.0
    thumb=im.resize(THUMB_SIZE,Image.Resampling.LANCZOS)
    return {
      'brightness':float(lum.mean()), 'contrast':float(lum.std()),
      'saturation':float(sat.mean()), 'temperature':float((pix[:,0]-pix[:,2]).mean()),
      'edge_density':edge, 'hist':[round(float(x),7) for x in hist],
      'coarse':[round(float(x),6) for x in coarse.reshape(-1)],
      'thumbnail_rgb_b64':base64.b64encode(np.asarray(thumb,dtype=np.uint8).tobytes()).decode('ascii'),
    }

def sim_scalar(a,b,span): return max(0.0,1.0-abs(a-b)/span)

def hist_intersection(a,b):
    a=np.array(a); b=np.array(b)
    return float(np.minimum(a,b).sum()/3.0)

def coarse_corr(a,b):
    a=np.array(a,dtype=np.float64); b=np.array(b,dtype=np.float64)
    a=(a-a.mean())/(a.std()+1e-9); b=(b-b.mean())/(b.std()+1e-9)
    c=float(np.corrcoef(a,b)[0,1])
    return max(0.0,min(1.0,(c+1.0)/2.0))

def thumb_from_profile(p):
    raw=base64.b64decode(p['thumbnail_rgb_b64'])
    return Image.frombytes('RGB',THUMB_SIZE,raw)

def global_ssim(a,b):
    x=np.asarray(a.convert('L')).astype(np.float64)/255.0
    y=np.asarray(b.convert('L')).astype(np.float64)/255.0
    mux,muy=x.mean(),y.mean(); vx,vy=x.var(),y.var()
    cov=((x-mux)*(y-muy)).mean()
    c1=0.01**2; c2=0.03**2
    val=((2*mux*muy+c1)*(2*cov+c2))/((mux*mux+muy*muy+c1)*(vx+vy+c2))
    return float(max(-1.0,min(1.0,val)))

def compare(cur_im,target):
    cur=image_metrics(cur_im)
    ref_thumb=thumb_from_profile(target)
    cur_thumb=cur_im.resize(THUMB_SIZE,Image.Resampling.LANCZOS)
    ca=np.asarray(cur_thumb.filter(ImageFilter.GaussianBlur(1.5))).astype(np.float32)/255
    ra=np.asarray(ref_thumb.filter(ImageFilter.GaussianBlur(1.5))).astype(np.float32)/255
    mae=float(np.abs(ca-ra).mean())
    sims={
      'brightness':sim_scalar(cur['brightness'],target['brightness'],0.45),
      'contrast':sim_scalar(cur['contrast'],target['contrast'],0.30),
      'saturation':sim_scalar(cur['saturation'],target['saturation'],0.45),
      'temperature':sim_scalar(cur['temperature'],target['temperature'],0.35),
      'palette':hist_intersection(cur['hist'],target['hist']),
      'edge_density':sim_scalar(cur['edge_density'],target['edge_density'],0.35),
      'coarse_structure':coarse_corr(cur['coarse'],target['coarse']),
      'perceptual_blur':max(0.0,1.0-mae/0.48),
      'ssim_global':global_ssim(cur_thumb,ref_thumb),
    }
    score=sum(sims[k]*w for k,w in WEIGHTS.items())/sum(WEIGHTS.values())
    return cur,sims,float(score),cur_thumb,ref_thumb

def recs(cur,tgt,sims):
    out=[]
    d=cur['brightness']-tgt['brightness']
    if d>0.055: out.append(f'Scene is too bright versus reference (+{d:.2f} luminance); reduce key/fill or exposure.')
    elif d<-0.055: out.append(f'Scene is too dark versus reference ({d:.2f} luminance); raise ambient/window fill.')
    d=cur['temperature']-tgt['temperature']
    if d>0.045: out.append('Color balance is too warm/red; cool neutral surfaces and reduce orange spill.')
    elif d<-0.045: out.append('Color balance is too cool; add warm sunlight/window bounce.')
    if cur['edge_density'] < tgt['edge_density']*0.78: out.append('Silhouette/detail density is below reference; final meshes/environment need more authored shape detail.')
    if sims['coarse_structure']<0.55: out.append('Camera/framing differs strongly from reference; adjust board occupancy, pitch and focal length.')
    if sims['palette']<0.72: out.append('Material palette is still far from the reference; tune wood/marble/stone/character colors.')
    if cur['saturation'] > tgt['saturation']+0.055: out.append('Saturation is too high; reduce saturated accent spill.')
    if not out: out.append('No major style-stat deviation detected; focus next on final meshes, rigging and authored animation.')
    return out

def diagnostic_images(name,cur_thumb,ref_thumb,outdir):
    w,h=ANALYSIS_SIZE
    cur=cur_thumb.resize(ANALYSIS_SIZE,Image.Resampling.BICUBIC)
    ref=ref_thumb.resize(ANALYSIS_SIZE,Image.Resampling.BICUBIC)
    side=Image.new('RGB',(w*2,h),(20,20,20)); side.paste(ref,(0,0)); side.paste(cur,(w,0))
    d=ImageDraw.Draw(side)
    d.rectangle((0,0,150,24),fill=(0,0,0)); d.text((8,5),'REFERENCE',fill='white')
    d.rectangle((w,0,w+120,24),fill=(0,0,0)); d.text((w+8,5),'CURRENT',fill='white')
    side.save(outdir/f'{name}_side_by_side.png')
    a=np.asarray(cur_thumb).astype(np.int16); b=np.asarray(ref_thumb).astype(np.int16)
    diff=np.abs(a-b).mean(axis=2).astype(np.uint8)
    heat=np.stack([diff, np.zeros_like(diff), 255-diff],axis=2)
    Image.fromarray(heat,'RGB').resize(ANALYSIS_SIZE,Image.Resampling.NEAREST).save(outdir/f'{name}_diff.png')

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--gameplay',required=True); ap.add_argument('--battle',required=True)
    ap.add_argument('--profile',required=True); ap.add_argument('--baseline',required=False)
    ap.add_argument('--out',required=True); ap.add_argument('--regression-tolerance',type=float,default=0.04)
    args=ap.parse_args(); out=Path(args.out); out.mkdir(parents=True,exist_ok=True)
    profile=json.load(open(args.profile,'r',encoding='utf-8'))
    baseline=json.load(open(args.baseline,'r',encoding='utf-8')) if args.baseline and os.path.exists(args.baseline) else {}
    report={'analysis_version':profile['analysis_version'],'source_reference':profile['source_reference'],'comparisons':{},'regression_failures':[]}
    md=['# Battle Chess Visual QA','']
    for name,path in [('gameplay',args.gameplay),('battle',args.battle)]:
        cur_im=load_rgb(path); cur,sims,score,ct,rt=compare(cur_im,profile[name])
        recommendations=recs(cur,profile[name],sims)
        base=float(baseline.get(name,{}).get('score',score))
        delta=score-base
        if score < base-args.regression_tolerance:
            report['regression_failures'].append(f'{name}: score {score:.3f} < baseline {base:.3f} - tolerance {args.regression_tolerance:.3f}')
        report['comparisons'][name]={
          'score':round(score,4),'score_percent':round(score*100,1),'baseline_score':round(base,4),'delta_from_baseline':round(delta,4),
          'similarity':{k:round(float(v),4) for k,v in sims.items()},
          'current_metrics':{k:round(float(v),5) for k,v in cur.items() if k not in ('hist','coarse','thumbnail_rgb_b64')},
          'target_metrics':{k:round(float(profile[name][k]),5) for k in ('brightness','contrast','saturation','temperature','edge_density')},
          'recommendations':recommendations,
        }
        diagnostic_images(name,ct,rt,out)
        md += [f'## {name.title()}',f'- Reference similarity: **{score*100:.1f}%**',f'- Baseline: {base*100:.1f}% ({delta*100:+.1f} pp)',f'- Palette: {sims["palette"]*100:.1f}%',f'- Framing/coarse structure: {sims["coarse_structure"]*100:.1f}%',f'- Edge/detail density: {sims["edge_density"]*100:.1f}%',f'- Diagnostic SSIM: {sims["ssim_global"]:.3f}','', '### Recommended next fixes']
        md += [f'- {r}' for r in recommendations]; md.append('')
    report['gate']='FAIL' if report['regression_failures'] else 'PASS'
    json.dump(report,open(out/'report.json','w',encoding='utf-8'),indent=2,ensure_ascii=False)
    md += ['## Regression gate',f'**{report["gate"]}**']
    if report['regression_failures']: md += [f'- {x}' for x in report['regression_failures']]
    open(out/'report.md','w',encoding='utf-8').write('\n'.join(md)+'\n')
    print(json.dumps({k:v['score_percent'] for k,v in report['comparisons'].items()},ensure_ascii=False))
    print('VISUAL_QA_'+report['gate'])
    return 2 if report['regression_failures'] else 0

if __name__=='__main__': sys.exit(main())
