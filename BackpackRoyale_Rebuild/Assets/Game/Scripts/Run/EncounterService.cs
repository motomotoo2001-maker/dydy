using System;
using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class EncounterService
    {
        private readonly List<EnemyData> enemies = new List<EnemyData>();
        private readonly int seed;

        public EncounterService(IEnumerable<EnemyData> roster, int valueSeed)
        {
            if (roster != null)
            {
                foreach (EnemyData enemy in roster)
                    if (enemy != null)
                        enemies.Add(enemy);
            }
            seed = valueSeed;
        }

        public EnemyData SelectEnemy(int stage, RunNodeType nodeType)
        {
            if (enemies.Count == 0)
                return null;
            if (nodeType == RunNodeType.Boss)
                return enemies[enemies.Count - 1];

            int regularCount = Math.Max(1, enemies.Count - 1);
            int safeStage = Math.Max(1, stage);
            int baseIndex = PositiveMod(seed + safeStage * 31, regularCount);
            if (nodeType == RunNodeType.Elite && regularCount > 1)
                baseIndex = (baseIndex + 1) % regularCount;
            return enemies[baseIndex];
        }

        private static int PositiveMod(int value, int divisor)
        {
            int result = value % divisor;
            return result < 0 ? result + divisor : result;
        }
    }
}
