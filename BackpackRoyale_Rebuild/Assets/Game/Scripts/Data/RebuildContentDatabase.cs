using UnityEngine;

namespace BackpackRoyale.Rebuild
{
    [CreateAssetMenu(menuName = "Backpack Royale/Rebuild/Content Database")]
    public sealed class RebuildContentDatabase : ScriptableObject
    {
        [SerializeField] private HeroData hero;
        [SerializeField] private EnemyData enemy;
        [SerializeField] private HeroData[] heroes;
        [SerializeField] private EnemyData[] enemies;
        [SerializeField] private ItemData[] items;
        [SerializeField] private FusionRecipe fusionRecipe;

        public HeroData[] Heroes => heroes != null && heroes.Length > 0 ? heroes : hero != null ? new[] { hero } : System.Array.Empty<HeroData>();
        public EnemyData[] Enemies => enemies != null && enemies.Length > 0 ? enemies : enemy != null ? new[] { enemy } : System.Array.Empty<EnemyData>();
        public HeroData Hero => Heroes.Length > 0 ? Heroes[0] : null;
        public EnemyData Enemy => Enemies.Length > 0 ? Enemies[0] : null;
        public ItemData[] Items => items;
        public FusionRecipe FusionRecipe => fusionRecipe;

        public void Configure(HeroData[] valueHeroes, EnemyData[] valueEnemies, ItemData[] valueItems, FusionRecipe recipe)
        {
            heroes = valueHeroes ?? System.Array.Empty<HeroData>();
            enemies = valueEnemies ?? System.Array.Empty<EnemyData>();
            hero = heroes.Length > 0 ? heroes[0] : null;
            enemy = enemies.Length > 0 ? enemies[0] : null;
            items = valueItems;
            fusionRecipe = recipe;
        }

        public void Configure(HeroData valueHero, EnemyData valueEnemy, ItemData[] valueItems, FusionRecipe recipe) =>
            Configure(valueHero != null ? new[] { valueHero } : System.Array.Empty<HeroData>(), valueEnemy != null ? new[] { valueEnemy } : System.Array.Empty<EnemyData>(), valueItems, recipe);

        public HeroData FindHero(string heroId)
        {
            foreach (HeroData value in Heroes)
                if (value != null && value.Id == heroId)
                    return value;
            return null;
        }

        public EnemyData FindEnemy(string enemyId)
        {
            foreach (EnemyData value in Enemies)
                if (value != null && value.Id == enemyId)
                    return value;
            return null;
        }

        public ItemData FindItem(string itemId)
        {
            if (items == null) return null;
            foreach (ItemData item in items)
                if (item != null && item.Id == itemId) return item;
            return null;
        }
    }
}
