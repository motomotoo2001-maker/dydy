using System;

namespace BackpackRoyale.Rebuild
{
    public enum BattleResult
    {
        Ongoing,
        PlayerWin,
        EnemyWin,
        Draw
    }

    public sealed class BattleController
    {
        public CombatantRuntime Player { get; }
        public CombatantRuntime Enemy { get; }
        public BattleResult Result { get; private set; } = BattleResult.Ongoing;
        public float Elapsed { get; private set; }

        public event Action<BattleActionEvent> ActionResolved;

        public BattleController(CombatantRuntime player, CombatantRuntime enemy)
        {
            Player = player;
            Enemy = enemy;
        }

        public void Tick(float dt)
        {
            if (Result != BattleResult.Ongoing || dt <= 0f)
                return;

            Elapsed += dt;
            TickOne(Player, Enemy, dt);
            if (Enemy.Dead)
            {
                Result = BattleResult.PlayerWin;
                return;
            }

            TickOne(Enemy, Player, dt);
            if (Player.Dead)
            {
                Result = BattleResult.EnemyWin;
                return;
            }

            if (Elapsed >= 45f)
            {
                float playerRatio = Player.Health / Player.Stats.MaxHealth;
                float enemyRatio = Enemy.Health / Enemy.Stats.MaxHealth;
                Result = playerRatio > enemyRatio
                    ? BattleResult.PlayerWin
                    : enemyRatio > playerRatio
                        ? BattleResult.EnemyWin
                        : BattleResult.Draw;
            }
        }

        private void TickOne(CombatantRuntime actor, CombatantRuntime target, float dt)
        {
            if (actor.Dead)
                return;

            float dot = actor.Statuses.Tick(dt);
            if (dot > 0f)
                DamageSystem.Apply(actor, dot, DamageType.Poison);
            if (actor.Dead)
                return;

            actor.AddMana(actor.Stats.ManaRegen * dt);
            foreach (var ability in actor.Abilities)
                ability.Tick(dt);

            foreach (var ability in actor.Abilities)
            {
                if (!ability.Ready || !actor.SpendMana(ability.Data.ManaCost))
                    continue;

                float multiplier = ability.Data.Ultimate
                    ? actor.Stats.UltimatePowerMultiplier
                    : actor.Stats.PowerMultiplier;
                float dealt = DamageSystem.Apply(target, ability.Data.BasePower * multiplier, ability.Data.DamageType);
                if (ability.Data.Status != StatusEffectKind.None)
                    target.Statuses.Apply(ability.Data.Status, ability.Data.StatusPower, ability.Data.StatusDuration);
                ability.Trigger();
                ActionResolved?.Invoke(new BattleActionEvent(
                    actor,
                    target,
                    ability.Data.DisplayName,
                    dealt,
                    ability.Data.DamageType,
                    ability.Data.Ultimate));
                return;
            }

            float speed = actor.Stats.AttackSpeed * (actor.Statuses.Frozen ? 0.5f : 1f);
            actor.BasicAttackTimer -= dt;
            if (actor.BasicAttackTimer <= 0f && speed > 0f)
            {
                float dealt = DamageSystem.Apply(target, actor.Stats.BaseDamage * actor.Stats.PowerMultiplier, DamageType.Physical);
                actor.AddMana(10f);
                actor.BasicAttackTimer = 1f / speed;
                ActionResolved?.Invoke(new BattleActionEvent(actor, target, "Basic Attack", dealt, DamageType.Physical, false));
            }
        }

        public static CombatantRuntime CreatePlayer(HeroData hero, BuildSnapshot build) =>
            new CombatantRuntime(hero.DisplayName, CombatStats.FromBuild(build), hero.Abilities);

        public static CombatantRuntime CreateEnemy(EnemyData enemy) =>
            CreateEnemy(
                enemy,
                new CombatStats
                {
                    MaxHealth = enemy.MaxHealth,
                    MaxMana = enemy.MaxMana,
                    Armor = enemy.Armor,
                    AttackSpeed = enemy.AttackSpeed,
                    BaseDamage = enemy.BaseDamage,
                    ManaRegen = enemy.ManaRegen,
                });

        public static CombatantRuntime CreateEnemy(EnemyData enemy, CombatStats stats) =>
            new CombatantRuntime(enemy.DisplayName, stats, enemy.Abilities);
    }
}
