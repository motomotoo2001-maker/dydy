using System;
using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RunMapService
    {
        private readonly int seed;
        private static readonly RunNodeType[] EventTypes =
        {
            RunNodeType.Shop,
            RunNodeType.Treasure,
            RunNodeType.Rest
        };

        public RunMapService(int valueSeed)
        {
            seed = valueSeed;
        }

        public RunMapState Generate(int stages)
        {
            int maxStage = Math.Max(2, stages);
            var nodes = new List<RunNode>
            {
                new RunNode("stage_1_battle", 1, RunNodeType.Battle, "Opening Battle")
            };

            var random = new Random(seed);
            int eventOffset = Math.Abs(seed % EventTypes.Length);
            for (int stage = 2; stage < maxStage; stage++)
            {
                RunNodeType combatType = random.Next(0, 3) == 0 ? RunNodeType.Elite : RunNodeType.Battle;
                RunNodeType eventType = EventTypes[(eventOffset + stage - 2) % EventTypes.Length];

                var combat = new RunNode(
                    $"stage_{stage}_{combatType.ToString().ToLowerInvariant()}",
                    stage,
                    combatType,
                    combatType == RunNodeType.Elite ? $"Elite {stage}" : $"Battle {stage}");
                var runEvent = new RunNode(
                    $"stage_{stage}_{eventType.ToString().ToLowerInvariant()}",
                    stage,
                    eventType,
                    EventLabel(eventType));

                if (random.Next(0, 2) == 0)
                {
                    nodes.Add(combat);
                    nodes.Add(runEvent);
                }
                else
                {
                    nodes.Add(runEvent);
                    nodes.Add(combat);
                }
            }

            nodes.Add(new RunNode($"stage_{maxStage}_boss", maxStage, RunNodeType.Boss, "Final Boss"));
            return new RunMapState(nodes, maxStage);
        }

        private static string EventLabel(RunNodeType type)
        {
            switch (type)
            {
                case RunNodeType.Shop: return "Merchant Camp";
                case RunNodeType.Treasure: return "Treasure Cache";
                case RunNodeType.Rest: return "Sacred Rest";
                default: return type.ToString();
            }
        }
    }
}
