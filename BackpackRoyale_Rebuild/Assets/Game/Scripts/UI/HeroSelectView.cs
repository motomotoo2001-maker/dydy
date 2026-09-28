using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BackpackRoyale.Rebuild
{
    public sealed class HeroSelectView : MonoBehaviour
    {
        [SerializeField] private TMP_Text title;
        [SerializeField] private Button[] heroButtons;
        [SerializeField] private TMP_Text[] heroLabels;
        [SerializeField] private Image[] heroPortraits;

        public void Setup(TMP_Text titleText, Button[] buttons, TMP_Text[] labels, Image[] portraits)
        {
            title = titleText;
            heroButtons = buttons;
            heroLabels = labels;
            heroPortraits = portraits;
        }

        public void Bind(IReadOnlyList<HeroData> heroes, Action<HeroData> selected)
        {
            if (title != null) title.text = "CHOOSE YOUR HERO";
            int count = heroButtons == null ? 0 : heroButtons.Length;
            for (int i = 0; i < count; i++)
            {
                bool visible = heroes != null && i < heroes.Count && heroes[i] != null;
                Button button = heroButtons[i];
                if (button == null) continue;
                button.gameObject.SetActive(visible);
                button.onClick.RemoveAllListeners();
                if (!visible) continue;
                HeroData hero = heroes[i];
                if (heroLabels != null && i < heroLabels.Length && heroLabels[i] != null)
                    heroLabels[i].text = hero.DisplayName.ToUpperInvariant();
                button.onClick.AddListener(() => selected?.Invoke(hero));
            }
        }

        public void SetPortrait(int index, Sprite sprite)
        {
            if (heroPortraits == null || index < 0 || index >= heroPortraits.Length || heroPortraits[index] == null) return;
            heroPortraits[index].sprite = sprite;
            heroPortraits[index].preserveAspect = true;
        }
    }
}
