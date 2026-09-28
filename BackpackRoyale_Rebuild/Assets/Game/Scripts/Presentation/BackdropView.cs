using UnityEngine;

namespace BackpackRoyale.Rebuild
{
    public enum BackdropMode
    {
        Hero,
        Build,
        Battle,
        RunMap
    }

    public sealed class BackdropView : MonoBehaviour
    {
        [SerializeField] private SpriteRenderer spriteRenderer;
        [SerializeField] private Camera targetCamera;
        [SerializeField] private Sprite heroSprite;
        [SerializeField] private Sprite buildSprite;
        [SerializeField] private Sprite battleSprite;
        [SerializeField] private Sprite runMapSprite;

        public void Setup(SpriteRenderer renderer, Camera camera, Sprite hero, Sprite build, Sprite battle, Sprite runMap)
        {
            spriteRenderer = renderer;
            targetCamera = camera;
            heroSprite = hero;
            buildSprite = build;
            battleSprite = battle;
            runMapSprite = runMap;
        }

        public void Show(BackdropMode mode)
        {
            if (spriteRenderer == null)
                return;

            switch (mode)
            {
                case BackdropMode.Hero:
                    spriteRenderer.sprite = heroSprite;
                    break;
                case BackdropMode.Battle:
                    spriteRenderer.sprite = battleSprite;
                    break;
                case BackdropMode.RunMap:
                    spriteRenderer.sprite = runMapSprite;
                    break;
                default:
                    spriteRenderer.sprite = buildSprite;
                    break;
            }
            FitToCamera();
        }

        private void FitToCamera()
        {
            if (spriteRenderer == null || spriteRenderer.sprite == null || targetCamera == null)
                return;

            Vector2 spriteSize = spriteRenderer.sprite.bounds.size;
            if (spriteSize.x <= 0f || spriteSize.y <= 0f)
                return;

            float worldHeight = targetCamera.orthographicSize * 2f;
            float worldWidth = worldHeight * targetCamera.aspect;
            float scale = Mathf.Max(worldWidth / spriteSize.x, worldHeight / spriteSize.y);
            transform.localScale = new Vector3(scale, scale, 1f);
        }
    }
}
