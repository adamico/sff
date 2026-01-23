# Question 1

> your role is a game design assistant. your task is to advice on the minimum number of components/systems to implement in order to test if the idea of the creature factory game is viable. Be language/engine/framework agnostic and focus on the gameplay aspect only.

## Minimum Testable Core

**The Central Question:** Does "automate creature production → deploy creatures → harvest resources → reinvest in automation" create engaging gameplay?

**Essential Systems (Priority Order):**

**1. Basic Creature Assembly (Single Chain)**

- 2-3 material types (e.g., bones, flesh, essence)
- 1 processing step (combine materials → creature)
- Manual placement/connection initially (no need for conveyors yet)
- One creature type is enough

**2. Mana Economy**

- Mana as a spendable resource (visible counter)
- One mana sink: synthesizing raw materials
- One mana source: deploying creatures to "harvest" (can be abstracted as: click creature → spend time → gain mana)

**3. Recycling Loop**

- Creatures can be broken back down into materials
- Return percentage matters (60%? 80%? This is a key tuning parameter)

**What This Tests:**

- Is the production → deployment → harvest → recycle loop satisfying?
- Does the mana economy create interesting decisions (spend on new materials vs save for expansion)?
- Can you achieve "break even" where recycled materials sustain production?

## What You DON'T Need Yet

- Conveyors/pipes (manual material movement is fine)
- Multiple creature types (variety isn't the question, viability is)
- Combat mechanics (abstract it: creature goes away, mana comes back)
- Rare materials (complexity doesn't prove core loop)
- Automation buildings (the goal, but not needed to test if the goal is worth pursuing)
- Graphics/art (rectangles and labels work fine)

## The Prototype Test Questions

After 15-30 minutes of play, ask yourself:

1. **Does the economy work?** Can you reach a sustainable state or does it spiral into mana deficit/surplus too easily?
2. **Are decisions interesting?** When choosing between recycling vs deploying, making new creatures vs synthesizing materials, do you pause to think?
3. **Does expansion feel earned?** When you can finally afford a second production line, does it feel like progression?
4. **Is there a "next goal"?** Do you naturally think "if I could just automate X" or "I need more of Y"?

## Success Criteria

The idea is **viable** if:

- Players can achieve self-sustainability without it being trivial
- The resource loop creates tension (temporary shortages, strategic choices)
- There's a clear desire for automation (doing it manually feels tedious in a motivating way)

The idea **needs rework** if:

- Economy is too easily broken (infinite mana or impossible to progress)
- Decisions feel arbitrary (no clear better choice)
- Players don't naturally want to build more/automate

## Next Steps After Validation

If the core loop works, then layer in complexity in this order:

1. Simple automation (conveyors/pipes)
2. Second creature type (tests recipe variety)
3. Multi-step processing (tests chain depth)
4. Combat mechanics (if conflict mode is important)
5. Rare materials (adds discovery/progression)

Does this minimal scope feel testable? The hardest part will be tuning the mana economy parameters—that's where the viability really lives.

# Question 2

> your task is now to help build the game data architecture. Use a structure similar to this example (refine the names and fields if necessary):

```xml
<example>
   <material>
    <name>Bones</name>
    <category>Structural component</category>
   </material>
   <processing>
    <name>create skeleton</name>
    <ingredients>Bones, Unlife essence</ingredients>
    <product>Skeleton</product>
   <cost>10 mana</cost>
   <category>final processing</category>
   </processing>
</example>
```

Here's a refined data architecture for your minimum viable prototype:

```xml
<!-- MATERIALS -->
<material>
  <id>bone</id>
  <name>Bone</name>
  <category>structural</category>
  <synthesisCost>5</synthesisCost> <!-- mana cost to create from nothing -->
</material>

<material>
  <id>flesh</id>
  <name>Flesh</name>
  <category>organic</category>
  <synthesisCost>8</synthesisCost>
</material>

<material>
  <id>essence</id>
  <name>Unlife Essence</name>
  <category>catalyst</category>
  <synthesisCost>12</synthesisCost>
</material>

<!-- RECIPES -->
<recipe>
  <id>skeleton_assembly</id>
  <name>Assemble Skeleton</name>
  <inputs>
    <input material="bone" quantity="2"/>
    <input material="essence" quantity="1"/>
  </inputs>
  <output creature="skeleton" quantity="1"/>
  <processingTime>3</processingTime> <!-- seconds or ticks -->
  <mana_cost>10</mana_cost>
</recipe>

<!-- CREATURES -->
<creature>
  <id>skeleton</id>
  <name>Skeleton</name>
  <tier>basic</tier>
  <harvest_yield>25</harvest_yield> <!-- mana gained when deployed -->
  <harvest_time>5</harvest_time> <!-- time to complete harvest -->
  <recycle_returns>
    <return material="bone" quantity="1"/> <!-- 50% return on bones -->
    <return material="essence" quantity="1"/> <!-- 100% return on essence -->
  </recycle_returns>
</creature>

<!-- BUILDINGS (for when you add automation) -->
<building>
  <id>assembly_station</id>
  <name>Assembly Station</name>
  <processes_recipe>skeleton_assembly</processes_recipe>
  <manaPerTick>1</manaPerTick> <!-- operating cost -->
  <build_cost>
    <cost material="bone" quantity="5"/>
    <cost mana="50"/>
  </build_cost>
</building>
```

## Key Design Decisions in This Structure

**Material Synthesis Cost:**

- Allows direct mana → material conversion
- Creates baseline material value
- Higher cost = more precious material

**Recipe Structure:**

- `inputs` array supports multiple materials at different quantities
- `output` specifies what's created
- `processingTime` enables time-based gameplay
- `mana_cost` is separate from material costs (ritual energy vs resources)

**Creature Data:**

- `harvest_yield` and `harvest_time` define the mana ROI and pacing
- `recycle_returns` can have different percentages per material (flexible balancing)
- `tier` metadata for future expansion

**Critical Ratios to Test:**

With the example skeleton:

- **Cost:** (2 bone × 5) + (1 essence × 12) + 10 mana = 32 mana equivalent
- **Return:** 25 mana harvest + (1 bone × 5) + (1 essence × 12) recycled = 42 mana equivalent
- **Net profit:** 10 mana (31% ROI)

This means skeletons are profitable but require the full cycle. You'll want to tune these numbers during testing.

## Alternative Considerations

**If you want percentage-based recycling instead:**

```xml
<recycle_returns type="percentage" value="0.6"/> <!-- returns 60% of all inputs -->
```

**If processing happens at buildings (not global):**

```xml
<recipe>
  <requires_building>assembly_station</requires_building>
</recipe>
```

**If creatures degrade over time:**

```xml
<creature>
  <lifespan>30</lifespan> <!-- seconds before creature dies/must be used -->
</creature>
```

Does this structure give you enough flexibility for prototyping? The key is keeping it simple enough to hand-edit during balancing passes.

---

# REVISED MVP LOOP (Dungeon Management)

## Core Concept

**Genre**: Dungeon Keeper-style dungeon management game  
**Theme**: Alchemical creature creation using the four humors system

## The MVP Loop

```
Procedural Dungeon Generation
         ↓
Player Spawns at Center
         ↓
Explore Dungeon ←──────────┐
         ↓                  │
Encounter Wild Creatures    │
         ↓                  │
Kill Creatures ────────────┐│
         ↓                 ││
Extract Resources:         ││
  • Four Humors (Blood,    ││
    Yellow Bile, Black     ││
    Bile, Phlegm)          ││
  • Void Component         ││
         ↓                 ││
Process Resources:         ││
  • Humors → Create        ││
    Creatures (if recipe   ││
    discovered)            ││
  • Void → Mana            ││
         ↓                 ││
Deploy Created Creatures   ││
         ↓                 ││
Build Structures/Tools ────┘│
         ↓                  │
Expand Dungeon Control ────┘
```

## Essential Systems (Priority Order)

### 1. Procedural Dungeon Generation ⚡ CRITICAL

- Room-based dungeon layout
- Spawn wild creatures in rooms
- Player spawns at center room
- Exploration reveals new rooms

### 2. Resource Extraction System ⚡ CRITICAL

- **Kill wild creatures** → Extract humors + void
- Each creature drops specific humor ratios (based on creature type)
- Example: Skeleton drops 80% Black Bile, 20% Yellow Bile, 35% Void

### 3. Humor-Based Creature Creation

- **Recipes discovered** by encountering creatures in dungeon
- Combine humors to recreate creatures
- Example: 80 Black Bile + 20 Yellow Bile + 35 Void → Skeleton
- Created creatures can be deployed to defend/expand dungeon

### 4. Void Processing (REFINED)

Void is a **metaphysical component** (0-100%) that determines a creature's level of transcendence:

- **Mana Capacity**: `void% × 2` (e.g., 50% void = 100 mana)
- **Mana Regeneration**: Starting at 50% void, `(void% - 50) / 2` per second (e.g., 95% void = 22.5/s)
- **Physical Interaction**: Higher void = weaker physical presence

**Example Stats:**

| Entity | Void % | Max Mana | Mana Regen |
| :--- | :--- | :--- | :--- |
| Player | 50% | 100 | 0/s |
| Skeleton | 35% | 70 | 0/s |
| Ghost | 95% | 190 | 22.5/s |

**Implementation Notes:**
- Void is stored as a property on entity data
- Mana is derived from void at spawn time (TypeObject pattern)
- Void is NOT lootable in the current MVP

**Mana used for:**
  - Creatures special abilities
  - Powering structures
  - Crafting tools
  - Dungeon expansion

### 5. Basic Resource System (Choose One)

**Option A: Separate Basic Resources** (Wood, Stone, etc.)

- Dungeon contains resource nodes
- Harvest nodes for building materials
- Build structures: walls, doors, traps, workbenches
- More traditional dungeon management feel

**Option B: Humor → Basic Resource Conversion**

- Humors can be converted to building materials
- Example: Black Bile → Stone, Yellow Bile → Fire/Energy
- Simpler system, more alchemical theme
- Reduces resource types

**Recommendation**: **Option B** for MVP - keeps focus on humor system

## Minimum Testable Core

**The Central Question**: Does "explore → kill → extract humors → create creatures → expand control" create engaging gameplay?

### What You Need (Minimal)

1. **3-5 room dungeon** (procedurally connected)
2. **2 wild creature types** (e.g., Skeleton, Ghoul)
3. **4 humor types + void** as extractable resources
4. **1 creature recipe** (discovered by killing that creature type)
5. **Void → Mana** conversion
6. **1 deployable structure** (e.g., wall or trap) using humor-derived resources

### What You DON'T Need Yet

- Complex dungeon generation (BSP, etc.)
- Many creature types
- Advanced AI behaviors
- Automation systems
- Multiplayer/invasions
- Save/load

## Revised Data Architecture

```xml
<!-- HUMORS (Base Resources) -->
<humor>
  <id>blood</id>
  <name>Blood</name>
  <element>Air</element>
  <qualities>Hot, Moist</qualities>
  <color>#8B0000</color>
</humor>

<humor>
  <id>yellowBile</id>
  <name>Yellow Bile</name>
  <element>Fire</element>
  <qualities>Hot, Dry</qualities>
  <color>#FFD700</color>
</humor>

<humor>
  <id>blackBile</id>
  <name>Black Bile</name>
  <element>Earth</element>
  <qualities>Cold, Dry</qualities>
  <color>#1C1C1C</color>
</humor>

<humor>
  <id>phlegm</id>
  <name>Phlegm</name>
  <element>Water</element>
  <qualities>Cold, Moist</qualities>
  <color>#87CEEB</color>
</humor>

<humor>
  <id>void</id>
  <name>Void</name>
  <element>Aether</element>
  <qualities>Supernatural</qualities>
  <color>#9400D3</color>
  <convertToMana>true</convertToMana>
  <manaConversionRate>2</manaConversionRate> <!-- 1 void = 2 mana -->
</humor>

<!-- WILD CREATURES (Found in Dungeon) -->
<wildCreature>
  <id>skeleton</id>
  <name>Skeleton</name>
  <tier>basic</tier>
  <spawnWeight>high</spawnWeight>
  <loot>
    <humor id="blackBile" quantity="80"/>
    <humor id="yellowBile" quantity="20"/>
    <humor id="void" quantity="35"/>
  </loot>
  <health>20</health>
  <behavior>patrol</behavior>
</wildCreature>

<wildCreature>
  <id>ghoul</id>
  <name>Ghoul</name>
  <tier>basic</tier>
  <spawnWeight>medium</spawnWeight>
  <loot>
    <humor id="blackBile" quantity="70"/>
    <humor id="yellowBile" quantity="30"/>
    <humor id="void" quantity="25"/>
  </loot>
  <health>30</health>
  <behavior>aggressive</behavior>
</wildCreature>

<!-- CREATURE RECIPES (Discovered on Kill) -->
<recipe>
  <id>createSkeleton</id>
  <name>Summon Skeleton</name>
  <discoveredBy>killingCreature</discoveredBy> <!-- Unlock recipe by killing skeleton -->
  <inputs>
    <humor id="blackBile" quantity="80"/>
    <humor id="yellowBile" quantity="20"/>
    <humor id="void" quantity="35"/>
  </inputs>
  <output creature="skeleton" quantity="1"/>
  <processingTime>5</processingTime>
  <manaCost>10</manaCost>
</recipe>

<!-- BASIC RESOURCES (Converted from Humors) -->
<conversion>
  <id>bileToStone</id>
  <name>Transmute Stone</name>
  <input humor="blackBile" quantity="50"/>
  <output resource="stone" quantity="10"/>
</conversion>

<conversion>
  <id>bileToFuel</id>
  <name>Transmute Fuel</name>
  <input humor="yellowBile" quantity="50"/>
  <output resource="fuel" quantity="10"/>
</conversion>

<!-- STRUCTURES -->
<structure>
  <id>stoneWall</id>
  <name>Stone Wall</name>
  <buildCost>
    <resource id="stone" quantity="5"/>
  </buildCost>
  <manaCost>5</manaCost>
</structure>
```

## The Prototype Test Questions

After 15-30 minutes of play, ask yourself:

1. **Is exploration rewarding?** Does finding new creatures feel exciting?
2. **Is the humor system intuitive?** Can you understand what humors do?
3. **Does creature creation feel earned?** Is discovering recipes satisfying?
4. **Is the void → mana loop clear?** Do you understand the economy?
5. **Do you want to expand?** Is there a natural desire to control more rooms?

## Success Criteria

The idea is **viable** if:

- Players naturally explore to find new creatures
- The humor extraction → creature creation loop is satisfying
- Discovering recipes creates "aha!" moments
- Resource management creates interesting decisions
- Players want to expand their controlled territory

The idea **needs rework** if:

- Exploration feels aimless or unrewarding
- Humor system is confusing
- Creature creation feels arbitrary
- Economy is too simple or too complex
- No clear progression goals emerge

## Implementation Priority

### Phase 1: Core Loop (Week 1)

1. ✅ Basic dungeon generation (3-5 rooms)
2. ✅ Wild creature spawning (2 types)
3. ✅ Combat system (kill creatures)
4. ✅ Humor extraction on death (looting creature corpse)
5. ⚠️ Void → Mana conversion (for MVP with a tool to harvest void from living creatures and convert it to mana at a low rate)
6. ⚠️ Recipe discovery system

### Phase 2: Creation Loop (Week 2)

7. ⚠️ Creature assembly using humors
2. ⚠️ Deploy created creatures
3. ⚠️ Basic creature AI (follow player, attack hostile creatures)

### Phase 3: Expansion (Week 3)

10. ⚠️ Humor → Resource conversion
2. ⚠️ Structure building (walls, traps)
3. ⚠️ Room claiming mechanics

## Open Design Questions

### Q1: How are recipes discovered?

- **Option A**: Automatic on first kill (simple, clear)
- **Option B**: Requires "study" action on corpse (more depth)
- **Option C**: Random chance on kill (RNG element)

### Q2: What do deployed creatures do?

- **Option A**: Passive defense (attack intruders)
- **Option B**: Active patrol (guard rooms)
- **Option C**: Resource generation (produce humors over time)

### Q3: Basic resources - separate or converted?

- **Option A**: Separate resource nodes in dungeon (wood, stone)
- **Option B**: Convert humors to resources (alchemical theme)
- **Recommendation**: Option B for MVP simplicity

### Q4: What limits expansion?

- **Option A**: Mana cost to claim rooms
- **Option B**: Need creatures to defend claimed rooms
- **Option C**: Both (mana + creature requirements)
