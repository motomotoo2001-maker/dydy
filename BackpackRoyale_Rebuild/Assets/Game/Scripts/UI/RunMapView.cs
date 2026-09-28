using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BackpackRoyale.Rebuild
{
    public sealed class RunMapView : MonoBehaviour
    {
        [SerializeField] private TMP_Text title;
        [SerializeField] private Button[] nodeButtons;
        [SerializeField] private TMP_Text[] nodeLabels;

        public void Setup(TMP_Text titleText, Button[] buttons, TMP_Text[] labels)
        {
            title = titleText;
            nodeButtons = buttons;
            nodeLabels = labels;
        }

        public void Bind(int stage, IReadOnlyList<RunNode> choices, Action<RunNode> selected)
        {
            if (title != null)
                title.text = $"CHOOSE STAGE {stage}";

            int buttonCount = nodeButtons == null ? 0 : nodeButtons.Length;
            for (int i = 0; i < buttonCount; i++)
            {
                bool visible = choices != null && i < choices.Count;
                Button button = nodeButtons[i];
                if (button == null)
                    continue;

                button.gameObject.SetActive(visible);
                button.onClick.RemoveAllListeners();
                if (!visible)
                    continue;

                RunNode node = choices[i];
                if (nodeLabels != null && i < nodeLabels.Length && nodeLabels[i] != null)
                    nodeLabels[i].text = $"{node.Label}\n{node.Type.ToString().ToUpperInvariant()}";
                button.onClick.AddListener(() => selected?.Invoke(node));
            }
        }
    }
}
