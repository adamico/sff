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
  <synthesis_cost>5</synthesis_cost> <!-- mana cost to create from nothing -->
</material>

<material>
  <id>flesh</id>
  <name>Flesh</name>
  <category>organic</category>
  <synthesis_cost>8</synthesis_cost>
</material>

<material>
  <id>essence</id>
  <name>Unlife Essence</name>
  <category>catalyst</category>
  <synthesis_cost>12</synthesis_cost>
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
  <processing_time>3</processing_time> <!-- seconds or ticks -->
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
  <mana_per_tick>1</mana_per_tick> <!-- operating cost -->
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
- `processing_time` enables time-based gameplay
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
