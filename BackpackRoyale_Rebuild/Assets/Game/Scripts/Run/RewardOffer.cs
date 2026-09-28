using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RewardOffer
    {
        private readonly List<ItemData> items;
        public int Gold { get; }
        public IReadOnlyList<ItemData> Items => items;

        public RewardOffer(int gold, List<ItemData> valueItems)
        {
            Gold = gold;
            items = valueItems ?? new List<ItemData>();
        }
    }
}
