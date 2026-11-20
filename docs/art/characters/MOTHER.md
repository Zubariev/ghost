# Mother — third family member

Status: **EXPERIMENTAL — in production (started 2026-11-20).** Sequential rollout after grandma and
the father (user decision 2026-11-20).

**Her work.** Cleaning (GDD §5.1): the board's clean tasks — dirty rooms and closing the windows the
ghost opens (tasks.json `clean`, object_priority). Otherwise she wakes, eats at the table, rests in
the living room and sleeps, like the father.

## Identity

| Field | Value |
|---|---|
| Id | `mother` |
| Family role | Cleaning (GDD §5.1): keeps the house clean and in order |
| Age | about 39 |
| Personality | Medium mobility, medium courage; organised, brisk, practical, a little worn out by the house (GDD §5.4) |
| Height | 1.68 m — between grandma and the father |
| Body | Slim, upright, quick |
| Head-to-body | about 1 : 5.5 |
| Face | Oval face, a few freckles, hazel eyes, a determined mouth; fair skin |
| Hair | Auburn hair pulled up in a messy claw-clip bun, a few loose strands, a wide fabric headband |
| Clothing | A loose oatmeal cable-knit jumper with the sleeves pushed up to the elbows; high-waisted light-wash mom jeans |
| Shoes | White canvas trainers |
| Accessories | Yellow rubber cleaning gloves tucked in her back pocket, small silver hoop earrings, a plain wedding ring |
| Palette | Auburn, oatmeal, light denim, white, a touch of yellow |
| Posture | Upright, brisk, weight forward |
| Movement | Quick light steps, purposeful; tucks loose hair behind her ear |
| Expressions | Focused (cleaning), tired, alarmed (contact) |
| Activities | clean (board tasks: dirty rooms, open windows), eat, rest (sofa), sleep |
| Never changes | The auburn claw-clip bun and headband, the oatmeal jumper with pushed-up sleeves, light mom jeans, white trainers, yellow gloves in the pocket, 1.68 m |

**Identity prompt:**

> A mother of about 39 from the late 1990s: slim and upright (1.68 m), an oval face with a few
> freckles, hazel eyes and a determined mouth; auburn hair pulled up in a messy claw-clip bun with a
> few loose strands and a wide fabric headband; a loose oatmeal cable-knit jumper with the sleeves
> pushed up to the elbows; high-waisted light-wash mom jeans; white canvas trainers; yellow rubber
> cleaning gloves tucked in her back pocket; small silver hoop earrings.

## Lessons from grandma and the father (applied)

- Build the side view from the **straight** standing profile, never a mid-stride painting.
- Every moving part is painted **whole** on its own; fit it back with `place.gd` when the generator
  scales it up, mirror the profile to face right (`mirror.gd`).
- Every view at **one scale**; calibrate a painted pose by its head height against the turnaround.
- Check each generated pose for extra or missing limbs before using it.
