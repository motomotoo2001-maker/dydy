using System;

namespace BackpackRoyale.Rebuild
{
    public static class EnemyScalingService
    {
        public static CombatStats CreateScaledStats(EnemyData enemy, int round, RunNodeType nodeType)
        {
            if (enemy == null)
                throw new ArgumentNullException(nameof(enemy));

            int roundIndex = Math.Max(1, round) - 1;
            float healthMultiplier = 1f + 0.14f * roundIndex;
            float damageMultiplier = 1f + 0.09f * roundIndex;
            float armorMultiplier = 1f + 0.04f * roundIndex;
            float speedMultiplier = 1f + 0.015f * roundIndex;

            switch (nodeType)
            {
                case RunNodeType.Elite:
                    healthMultiplier *= 1.35f;
                    damageMultiplier *= 1.20f;
                    armorMultiplier *= 1.10f;
                    speedMultiplier *= 1.05f;
                    break;
                case RunNodeType.Boss:
                    healthMultiplier *= 1.80f;
                    damageMultiplier *= 1.45f;
                    armorMultiplier *= 1.25f;
                    speedMultiplier *= 1.08f;
                    break;
            }

            return new CombatStats
            {
                MaxHealth = enemy.MaxHealth * healthMultiplier,
                MaxMana = enemy.MaxMana,
                Armor = enemy.Armor * armorMultiplier,
                AttackSpeed = enemy.AttackSpeed * speedMultiplier,
                BaseDamage = enemy.BaseDamage * damageMultiplier,
                ManaRegen = enemy.ManaRegen * (1f + 0.03f * roundIndex),
            };
        }
    }
}
