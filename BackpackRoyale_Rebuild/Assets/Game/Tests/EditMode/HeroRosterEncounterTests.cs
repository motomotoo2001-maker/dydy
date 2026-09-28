using NUnit.Framework;
using UnityEngine;

namespace BackpackRoyale.Rebuild.Tests
{
    public sealed class HeroRosterEncounterTests
    {
        [Test]
        public void ContentDatabaseFindsHeroesAndEnemiesById()
        {
            var heroA = ScriptableObject.CreateInstance<HeroData>();
            var heroB = ScriptableObject.CreateInstance<HeroData>();
            heroA.Configure("hero_a", "Hero A", 100, 100, 1, 1, 10, 5, null);
            heroB.Configure("hero_b", "Hero B", 100, 100, 1, 1, 10, 5, null);
            var enemyA = ScriptableObject.CreateInstance<EnemyData>();
            var enemyB = ScriptableObject.CreateInstance<EnemyData>();
            enemyA.Configure("enemy_a", "Enemy A", 100, 100, 1, 1, 10, 5, null);
            enemyB.Configure("enemy_b", "Enemy B", 100, 100, 1, 1, 10, 5, null);
            var db = ScriptableObject.CreateInstance<RebuildContentDatabase>();
            db.Configure(new[] { heroA, heroB }, new[] { enemyA, enemyB }, null, null);
            Assert.AreEqual(heroB, db.FindHero("hero_b"));
            Assert.AreEqual(enemyA, db.FindEnemy("enemy_a"));
        }

        [Test]
        public void EncounterSelectionIsDeterministicAndBossUsesLastEnemy()
        {
            var a = Enemy("a");
            var b = Enemy("b");
            var c = Enemy("c");
            var d = Enemy("d");
            var serviceA = new EncounterService(new[] { a, b, c, d }, 1337);
            var serviceB = new EncounterService(new[] { a, b, c, d }, 1337);
            Assert.AreEqual(serviceA.SelectEnemy(3, RunNodeType.Battle).Id, serviceB.SelectEnemy(3, RunNodeType.Battle).Id);
            Assert.AreEqual(d, serviceA.SelectEnemy(6, RunNodeType.Boss));
            Assert.AreNotEqual(serviceA.SelectEnemy(2, RunNodeType.Battle), serviceA.SelectEnemy(2, RunNodeType.Elite));
        }

        private static EnemyData Enemy(string id)
        {
            var enemy = ScriptableObject.CreateInstance<EnemyData>();
            enemy.Configure(id, id, 100, 100, 1, 1, 10, 5, null);
            return enemy;
        }
    }
}
