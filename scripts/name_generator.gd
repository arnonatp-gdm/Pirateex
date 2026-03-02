# Name Generator

## Naming Specifications

### Captain Format
- Format: `Captain [Tool|Spell] [Job|Actioner] the [Temperament]`
- Derived from: `FactionData.tech_affinity` and `FactionData.cultural`

### Ship Format
- Format: `[Class] [lname] [fname]`
- Where: 
  - `lname` is `Material` if `cultural` else `Result`
  - `fname` is `StateOfMatter` if `tech_affinity` else `BodyPart`
- Default: `ship_class='Corvette'`

## Word Lists and Helper Functions

### Word Lists
- Tools and Spells: [List of tools and spells]
- Jobs and Actioners: [List of jobs and actioners]
- Temperaments: [List of temperaments]
- Materials: [List of materials]
- States of Matter: [List of states]
- Body Parts: [List of body parts]
- Results: [List of results]

### Helper Function _pick
```gdscript
func _pick(array):
    return array[randi() % array.size()]
```