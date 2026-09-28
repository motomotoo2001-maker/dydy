using System.Collections;
using UnityEngine;

namespace BackpackRoyale.Rebuild
{
    public sealed class CharacterView : MonoBehaviour
    {
        [SerializeField] private Animator animator;
        [SerializeField] private SpriteRenderer spriteRenderer;
        [SerializeField] private string[] visualIds;
        [SerializeField] private RuntimeAnimatorController[] visualControllers;
        [SerializeField] private Sprite[] visualIdleSprites;
        private Coroutine hitFlashRoutine;
        private Coroutine returnToIdleRoutine;

        public void Setup(Animator valueAnimator, SpriteRenderer valueRenderer)
        {
            animator = valueAnimator;
            spriteRenderer = valueRenderer;
        }

        public void SetupVisualLibrary(string[] ids, RuntimeAnimatorController[] controllers, Sprite[] idleSprites)
        {
            visualIds = ids;
            visualControllers = controllers;
            visualIdleSprites = idleSprites;
        }

        public bool UseVisual(string id)
        {
            if (string.IsNullOrEmpty(id) || visualIds == null) return false;
            for (int i = 0; i < visualIds.Length; i++)
            {
                if (visualIds[i] != id) continue;
                if (animator != null && visualControllers != null && i < visualControllers.Length)
                    animator.runtimeAnimatorController = visualControllers[i];
                if (spriteRenderer != null && visualIdleSprites != null && i < visualIdleSprites.Length)
                    spriteRenderer.sprite = visualIdleSprites[i];
                Play("Idle");
                return true;
            }
            return false;
        }

        public void Play(string state)
        {
            if (animator == null || animator.runtimeAnimatorController == null) return;
            animator.Play(state, 0, 0f);
            if (state == "Idle" || state == "Run" || state == "Death") return;
            if (returnToIdleRoutine != null) StopCoroutine(returnToIdleRoutine);
            float delay = state == "Ultimate" ? 0.78f : 0.42f;
            returnToIdleRoutine = StartCoroutine(ReturnToIdle(delay));
        }

        public void SetFacingLeft(bool left)
        {
            if (spriteRenderer != null) spriteRenderer.flipX = left;
        }

        public void FlashHit(Color color)
        {
            if (spriteRenderer == null) return;
            if (hitFlashRoutine != null) StopCoroutine(hitFlashRoutine);
            hitFlashRoutine = StartCoroutine(HitFlash(color));
        }

        private IEnumerator ReturnToIdle(float delay)
        {
            yield return new WaitForSeconds(delay);
            if (animator != null && animator.runtimeAnimatorController != null) animator.Play("Idle", 0, 0f);
            returnToIdleRoutine = null;
        }

        private IEnumerator HitFlash(Color color)
        {
            Color original = spriteRenderer.color;
            spriteRenderer.color = Color.Lerp(Color.white, color, 0.55f);
            yield return new WaitForSeconds(0.09f);
            spriteRenderer.color = original;
            hitFlashRoutine = null;
        }
    }
}
