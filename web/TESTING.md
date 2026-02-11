# What Now? - Testing Checklist

## Stage A Features - Manual Testing

### A5: Edit Tasks
- [ ] Click task in Manage Tasks opens edit screen
- [ ] Form pre-populates with task data (name, desc, type, time, social, energy, due date, recurring)
- [ ] All option buttons show correct selection state
- [ ] Changing options updates selection visually
- [ ] Save Changes updates the task
- [ ] Delete Task removes the task (with confirmation)
- [ ] Back button warns about unsaved changes when modified
- [ ] Back button navigates directly when no changes

### A3: Task Templates
- [ ] "From Saved Tasks" button hidden when no templates exist
- [ ] "Save as template" checkbox appears on details screen
- [ ] Saving with checkbox creates template
- [ ] "From Saved Tasks" button visible after template created
- [ ] Template list shows all saved templates
- [ ] Clicking template pre-fills task and goes to name/desc screen
- [ ] Delete button removes template
- [ ] Template button visibility updates after deletion

### A4: Points System + Levels
- [ ] Points calculated correctly: time (5-25) + social (5-20) + energy (5-20)
- [ ] Rank display hidden when 0 points
- [ ] Rank display shows after earning points
- [ ] Progress bar fills correctly toward next rank
- [ ] Rank titles correct at thresholds:
  - 0-99: Task Newbie
  - 100-499: Task Apprentice
  - 500-999: Task Warrior
  - 1000-2499: Task Hero
  - 2500-4999: Task Master
  - 5000+: Task Legend
- [ ] "Max rank achieved" shows at 5000+ points

### A2: Timer + Celebration
- [ ] "Start Timer" and "Mark as Done" buttons on accepted screen
- [ ] Timer screen shows task name
- [ ] Timer counts up from 00:00
- [ ] Pause button pauses timer, text changes to "Resume"
- [ ] Resume continues timer
- [ ] Cancel returns to accepted screen
- [ ] Done button shows celebration
- [ ] "Mark as Done" (skip timer) also shows celebration
- [ ] Celebration shows confetti animation
- [ ] Points earned displayed correctly
- [ ] Random motivational message shown
- [ ] Level-up banner appears when crossing rank threshold
- [ ] Continue button returns to home with updated rank

### A1: Due Date + Recurring + Urgency
- [ ] Step 6 (schedule) appears after name/desc
- [ ] Due date picker works
- [ ] Recurring options: None, Daily, Weekly, Monthly
- [ ] Skip button saves task without due date
- [ ] Save button saves with due date/recurring
- [ ] Overdue tasks show red indicator in Manage Tasks
- [ ] "Due today/tomorrow/in X days" labels appear
- [ ] Overdue/due soon badges on swipe cards
- [ ] Urgent tasks prioritized in matching (appear first)
- [ ] Completing recurring task sets next due date
- [ ] Edit task shows due date and recurring fields

### A6: Completed Tasks Gallery
- [ ] "Completed Gallery" button on home screen
- [ ] Stats show: Tasks Done, Points Earned, Time Spent
- [ ] Time format correct (Xh Xm)
- [ ] Fun comparison appears at milestones
- [ ] Sticker bomb grid shows completed tasks
- [ ] Tasks have type-colored left border
- [ ] Tasks show points earned
- [ ] Random rotation on stickers
- [ ] Hover removes rotation
- [ ] Empty state when no completed tasks

### A7: Multi-Add (Batch Tasks)
- [ ] "Multiple" button on type selection screen
- [ ] Type selection works
- [ ] Time selection advances to social
- [ ] Social selection advances to energy
- [ ] Energy selection advances to names screen
- [ ] 5 input fields available
- [ ] Save All creates tasks for non-empty fields
- [ ] Empty fields ignored
- [ ] Returns to home after save

### A8: Import from Notes
- [ ] "Import" button on type selection screen
- [ ] Textarea accepts pasted text
- [ ] File upload button works (.txt, .csv, .html)
- [ ] Parse Tasks button processes input
- [ ] Plain text: strips bullets, numbers, checkboxes
- [ ] CSV: finds name/task/title column
- [ ] Review screen shows parsed tasks with count
- [ ] Setup button opens task configuration
- [ ] All 4 options (type/time/social/energy) required
- [ ] Save button disabled until all selected
- [ ] Saving removes from pending, adds to tasks
- [ ] Delete button removes from pending
- [ ] "All imports processed" when list empty
- [ ] Back to Home button appears when done

---

## Edge Cases

### Offline Mode
- [ ] App loads when offline (service worker)
- [ ] All features work offline
- [ ] Data persists in localStorage
- [ ] No errors in console when offline

### Storage Limits
- [ ] App handles 100+ tasks
- [ ] App handles 200+ completed history entries
- [ ] Completed history prunes to 200
- [ ] Points history prunes to 100
- [ ] Templates stored separately

### Mobile Browsers
- [ ] Touch swipe works on cards
- [ ] All buttons tappable (44px+ touch targets)
- [ ] No horizontal scroll
- [ ] Safe area insets respected (notched phones)
- [ ] Date picker works on iOS/Android
- [ ] Keyboard doesn't obscure inputs

### Data Integrity
- [ ] Page refresh preserves all data
- [ ] Multiple browser tabs don't corrupt data
- [ ] Invalid localStorage gracefully handled

---

## Browser Compatibility

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Chrome Mobile (Android)
- [ ] Safari Mobile (iOS)

---

## E2E Test Candidates (Playwright/Cypress)

Priority tests to automate:
1. Full task creation flow (all 6 steps)
2. Task completion with timer → celebration
3. Template creation and usage
4. Import flow (text → review → setup → save)
5. Multi-add flow
6. Edit task flow
7. Points accumulation and rank progression
