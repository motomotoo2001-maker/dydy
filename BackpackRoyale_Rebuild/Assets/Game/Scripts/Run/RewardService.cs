using System;
using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RewardService
    {
        private readonly List<ItemData> pool;
        private readonly int seed;

        public RewardService(IEnumerable<ItemData> items, int valueSeed)
        {
            pool = new List<ItemData>();
            if (items != null)
            {
                foreach (ItemData item in items)
                    if (item != null)
                        pool.Add(item);
            }
            seed = valueSeed;
        }

        public RewardOffer CreateOffer(int round, RunNodeType nodeType, int itemChoiceCount)
        {
            int safeRound = Math.Max(1, round);
            int gold = 4 + safeRound;
            if (nodeType == RunNodeType.Elite)
                gold += 2;
            else if (nodeType == RunNodeType.Boss)
                gold += 6;

            int count = Math.Max(0, Math.Min(itemChoiceCount, pool.Count));
            var indices = new List<int>(pool.Count);
            for (int i = 0; i < pool.Count; i++)
                indices.Add(i);

            var random = new Random(seed ^ (safeRound * 48611) ^ ((int)nodeType * 7919));
            for (int i = indices.Count - 1; i > 0; i--)
            {
                int swapIndex = random.Next(i + 1);
                (indices[i], indices[swapIndex]) = (indices[swapIndex], indices[i]);
            }

            var choices = new List<ItemData>(count);
            for (int i = 0; i < count; i++)
                choices.Add(pool[indices[i]]);
            return new RewardOffer(gold, choices);
        }
    }
}
