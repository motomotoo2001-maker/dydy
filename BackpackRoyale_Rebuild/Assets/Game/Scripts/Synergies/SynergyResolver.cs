namespace BackpackRoyale.Rebuild
{
    public static class SynergyResolver
    {
        public static BuildSnapshot Calculate(HeroData hero, InventoryGrid grid)
        {
            var snapshot = BuildSnapshot.FromHero(hero);
            int fire = 0;
            int ice = 0;
            int poison = 0;
            int holy = 0;

            if (grid != null)
            {
                foreach (var item in grid.Items)
                {
                    ItemTag tags = item.Data.Tags;
                    if ((tags & ItemTag.Fire) != 0) fire++;
                    if ((tags & ItemTag.Ice) != 0) ice++;
                    if ((tags & ItemTag.Poison) != 0) poison++;
                    if ((tags & ItemTag.Holy) != 0) holy++;
                    snapshot.BaseDamage += item.Data.BonusDamage;
                    snapshot.AttackSpeed += item.Data.BonusAttackSpeed;
                    snapshot.Armor += item.Data.BonusArmor;
                    snapshot.MaxHealth += item.Data.BonusHealth;
                    snapshot.ManaRegen += item.Data.BonusManaRegen;
                }
            }

            if (fire >= 2) { snapshot.PowerMultiplier *= 1.20f; snapshot.ActiveSynergies.Add("Kindling II: +20% damage"); }
            if (fire >= 3) { snapshot.AttackSpeed *= 1.15f; snapshot.ActiveSynergies.Add("Wildfire III: +15% attack speed"); }
            if (ice >= 2) { snapshot.Armor += 6f; snapshot.ManaRegen += 1f; snapshot.ActiveSynergies.Add("Permafrost II: +6 armor, +1 mana regen"); }
            if (poison >= 2) { snapshot.BaseDamage += 4f; snapshot.AttackSpeed *= 1.12f; snapshot.ActiveSynergies.Add("Venom II: +4 damage, +12% attack speed"); }
            if (holy >= 2) { snapshot.MaxHealth *= 1.12f; snapshot.Armor += 4f; snapshot.ActiveSynergies.Add("Radiance II: +12% health, +4 armor"); }

            if (HeroCoreResolver.HasAdjacentTag(grid, ItemTag.Fire)) { snapshot.UltimatePowerMultiplier *= 1.25f; snapshot.ActiveSynergies.Add("Hero Core: Inferno +25% ultimate power"); }
            if (HeroCoreResolver.HasAdjacentTag(grid, ItemTag.Ice)) { snapshot.Armor += 6f; snapshot.ActiveSynergies.Add("Hero Core: Frozen Aegis +6 armor"); }
            if (HeroCoreResolver.HasAdjacentTag(grid, ItemTag.Poison)) { snapshot.AttackSpeed *= 1.10f; snapshot.ActiveSynergies.Add("Hero Core: Toxic Reflex +10% attack speed"); }
            if (HeroCoreResolver.HasAdjacentTag(grid, ItemTag.Holy)) { snapshot.MaxHealth += 10f; snapshot.ManaRegen += 1f; snapshot.ActiveSynergies.Add("Hero Core: Sacred Heart +10 health, +1 mana regen"); }
            return snapshot;
        }
    }
}
