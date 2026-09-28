using NUnit.Framework;
using UnityEngine;

namespace BackpackRoyale.Rebuild.Tests
{
    public sealed class RunProgressionTests
    {
        [Test]
        public void EnemyScalingIncreasesWithRoundAndNodeDifficulty()
        {
            var enemy = ScriptableObject.CreateInstance<EnemyData>();
            enemy.Configure("e", "Enemy", 100, 100, 5, 1, 10, 5, null);

            CombatStats round1 = EnemyScalingService.CreateScaledStats(enemy, 1, RunNodeType.Battle);
            CombatStats round4 = EnemyScalingService.CreateScaledStats(enemy, 4, RunNodeType.Battle);
            CombatStats elite = EnemyScalingService.CreateScaledStats(enemy, 4, RunNodeType.Elite);
            CombatStats boss = EnemyScalingService.CreateScaledStats(enemy, 4, RunNodeType.Boss);

            Assert.Greater(round4.MaxHealth, round1.MaxHealth);
            Assert.Greater(round4.BaseDamage, round1.BaseDamage);
            Assert.Greater(elite.MaxHealth, round4.MaxHealth);
            Assert.Greater(boss.MaxHealth, elite.MaxHealth);
        }

        [Test]
        public void RunMapIsDeterministicAndEndsInSingleBoss()
        {
            var a = new RunMapService(1337).Generate(6);
            var b = new RunMapService(1337).Generate(6);

            Assert.AreEqual(a.Nodes.Count, b.Nodes.Count);
            Assert.AreEqual(2, a.GetChoicesForStage(2).Count);
            Assert.AreEqual(1, a.GetChoicesForStage(6).Count);
            Assert.AreEqual(RunNodeType.Boss, a.GetChoicesForStage(6)[0].Type);
            for (int i = 0; i < a.Nodes.Count; i++)
                Assert.AreEqual(a.Nodes[i].Type, b.Nodes[i].Type);
        }

        [Test]
        public void RewardServiceReturnsDeterministicDistinctChoices()
        {
            ItemData a = ScriptableObject.CreateInstance<ItemData>();
            ItemData b = ScriptableObject.CreateInstance<ItemData>();
            ItemData c = ScriptableObject.CreateInstance<ItemData>();
            ItemData d = ScriptableObject.CreateInstance<ItemData>();
            a.Configure("a", "A", ItemRarity.Common, 1, 1, 1, ItemTag.Fire, 0, 0, 0, 0, 0, null);
            b.Configure("b", "B", ItemRarity.Common, 1, 1, 1, ItemTag.Fire, 0, 0, 0, 0, 0, null);
            c.Configure("c", "C", ItemRarity.Common, 1, 1, 1, ItemTag.Fire, 0, 0, 0, 0, 0, null);
            d.Configure("d", "D", ItemRarity.Common, 1, 1, 1, ItemTag.Fire, 0, 0, 0, 0, 0, null);

            var service = new RewardService(new[] { a, b, c, d }, 99);
            RewardOffer first = service.CreateOffer(3, RunNodeType.Elite, 3);
            RewardOffer second = new RewardService(new[] { a, b, c, d }, 99).CreateOffer(3, RunNodeType.Elite, 3);

            Assert.Greater(first.Gold, 0);
            Assert.AreEqual(3, first.Items.Count);
            Assert.AreEqual(first.Items[0].Id, second.Items[0].Id);
            Assert.AreNotEqual(first.Items[0].Id, first.Items[1].Id);
        }
    }
}
