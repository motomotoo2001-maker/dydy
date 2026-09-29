using System;

namespace BackpackRoyale.Rebuild
{
    public readonly struct RunEventResult
    {
        public int GoldDelta { get; }
        public float HealthBonus { get; }
        public string Message { get; }

        public RunEventResult(int goldDelta, float healthBonus, string message)
        {
            GoldDelta = goldDelta;
            HealthBonus = healthBonus;
            Message = message ?? string.Empty;
        }
    }

    public sealed class RunEventService
    {
        private readonly int seed;

        public RunEventService(int valueSeed)
        {
            seed = valueSeed;
        }

        public RunEventResult Resolve(RunNode node)
        {
            if (node == null)
                return new RunEventResult(0, 0f, "No event");

            int stage = Math.Max(1, node.Stage);
            switch (node.Type)
            {
                case RunNodeType.Shop:
                    return new RunEventResult(2 + stage / 3, 0f, "Merchant camp: travel stipend added. Shop freely, then continue.");
                case RunNodeType.Treasure:
                    return new RunEventResult(4 + stage, 0f, "Treasure cache opened: bonus gold acquired.");
                case RunNodeType.Rest:
                    return new RunEventResult(0, 8f + stage, "Sacred rest: maximum health increased for this run.");
                default:
                    return new RunEventResult(0, 0f, "Combat route selected.");
            }
        }
    }
}
