// @ts-check
const { test, expect } = require('@playwright/test');

// Clear localStorage before each test
test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => localStorage.clear());
  await page.reload();
});

test.describe('Home Screen', () => {
  test('shows app title and buttons', async ({ page }) => {
    await expect(page.locator('.app-title')).toHaveText('What Now?');
    await expect(page.locator('#btn-add-task')).toBeVisible();
    await expect(page.locator('#btn-what-next')).toBeVisible();
    await expect(page.locator('#btn-manage-tasks')).toBeVisible();
    await expect(page.locator('#btn-gallery')).toBeVisible();
  });

  test('rank display hidden when no points', async ({ page }) => {
    await expect(page.locator('#rank-display')).toHaveClass(/hidden/);
  });
});

test.describe('Task Creation Flow', () => {
  test('creates task through all 6 steps', async ({ page }) => {
    // Step 1: Click Add Task
    await page.click('#btn-add-task');
    await expect(page.locator('#screen-add-type')).toHaveClass(/active/);

    // Select task type
    await page.click('.type-option >> text=Chores');
    await expect(page.locator('#screen-add-time')).toHaveClass(/active/);

    // Step 2: Select time
    await page.click('.time-option >> text=15 min');
    await expect(page.locator('#screen-add-social')).toHaveClass(/active/);

    // Step 3: Select social
    await page.click('#screen-add-social .level-option >> text=Low');
    await expect(page.locator('#screen-add-energy')).toHaveClass(/active/);

    // Step 4: Select energy
    await page.click('#screen-add-energy .level-option >> text=Medium');
    await expect(page.locator('#screen-add-details')).toHaveClass(/active/);

    // Step 5: Enter name and description
    await page.fill('#task-name', 'Test Task');
    await page.fill('#task-desc', 'Test description');
    await page.click('#btn-next-to-schedule');
    await expect(page.locator('#screen-add-schedule')).toHaveClass(/active/);

    // Step 6: Skip schedule (or set due date)
    await page.click('#btn-skip-schedule');
    await expect(page.locator('#screen-home')).toHaveClass(/active/);

    // Verify task was created
    await page.click('#btn-manage-tasks');
    await expect(page.locator('.task-item-name')).toHaveText('Test Task');
  });

  test('creates task with due date and recurring', async ({ page }) => {
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Work');
    await page.click('.time-option >> text=30 min');
    await page.click('#screen-add-social .level-option >> text=Medium');
    await page.click('#screen-add-energy .level-option >> text=High');
    await page.fill('#task-name', 'Weekly Report');
    await page.click('#btn-next-to-schedule');

    // Set due date (tomorrow)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];
    await page.fill('#task-due-date', dateStr);

    // Set recurring
    await page.click('.recurring-option >> text=Weekly');
    await page.click('#btn-save-task');

    await expect(page.locator('#screen-home')).toHaveClass(/active/);
  });
});

test.describe('Task Completion with Timer', () => {
  test.beforeEach(async ({ page }) => {
    // Create a task first
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Health');
    await page.click('.time-option >> text=5 min');
    await page.click('#screen-add-social .level-option >> text=Low');
    await page.click('#screen-add-energy .level-option >> text=Low');
    await page.fill('#task-name', 'Quick Exercise');
    await page.click('#btn-next-to-schedule');
    await page.click('#btn-skip-schedule');
  });

  test('completes task with timer and shows celebration', async ({ page }) => {
    // Start What Next flow
    await page.click('#btn-what-next');

    // Select state
    await page.click('.state-btn[data-type="energy"][data-value="low"]');
    await page.click('.state-btn[data-type="social"][data-value="low"]');
    await page.click('.state-btn[data-type="time"][data-value="5"]');
    await page.click('#btn-find-task');

    // Swipe right to accept (simulate by clicking and dragging)
    const card = page.locator('.swipe-card').first();
    await card.dragTo(card, {
      sourcePosition: { x: 50, y: 200 },
      targetPosition: { x: 300, y: 200 },
    });

    // Should see accepted screen
    await expect(page.locator('#screen-accepted')).toHaveClass(/active/);
    await expect(page.locator('#btn-start-timer')).toBeVisible();

    // Start timer
    await page.click('#btn-start-timer');
    await expect(page.locator('#screen-timer')).toHaveClass(/active/);

    // Wait a moment for timer
    await page.waitForTimeout(1500);

    // Complete task
    await page.click('#btn-timer-done');

    // Should see celebration
    await expect(page.locator('#screen-celebration')).toHaveClass(/active/);
    await expect(page.locator('.points-earned')).toContainText('+');
    await expect(page.locator('#confetti-canvas')).toBeVisible();

    // Continue to home
    await page.click('#btn-celebration-done');
    await expect(page.locator('#screen-home')).toHaveClass(/active/);

    // Rank should now be visible
    await expect(page.locator('#rank-display')).not.toHaveClass(/hidden/);
  });

  test('completes task without timer (Mark as Done)', async ({ page }) => {
    await page.click('#btn-what-next');
    await page.click('.state-btn[data-type="energy"][data-value="low"]');
    await page.click('.state-btn[data-type="social"][data-value="low"]');
    await page.click('.state-btn[data-type="time"][data-value="5"]');
    await page.click('#btn-find-task');

    // Accept task
    const card = page.locator('.swipe-card').first();
    await card.dragTo(card, {
      sourcePosition: { x: 50, y: 200 },
      targetPosition: { x: 300, y: 200 },
    });

    // Mark as done directly
    await page.click('#btn-done');

    // Should see celebration
    await expect(page.locator('#screen-celebration')).toHaveClass(/active/);
  });
});

test.describe('Edit Tasks', () => {
  test.beforeEach(async ({ page }) => {
    // Create a task
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Admin');
    await page.click('.time-option >> text=15 min');
    await page.click('#screen-add-social .level-option >> text=Low');
    await page.click('#screen-add-energy .level-option >> text=Low');
    await page.fill('#task-name', 'Original Task');
    await page.click('#btn-next-to-schedule');
    await page.click('#btn-skip-schedule');
  });

  test('edits task name and saves', async ({ page }) => {
    await page.click('#btn-manage-tasks');
    await page.click('.task-item');

    await expect(page.locator('#screen-edit-task')).toHaveClass(/active/);
    await expect(page.locator('#edit-task-name')).toHaveValue('Original Task');

    await page.fill('#edit-task-name', 'Updated Task');
    await page.click('#btn-update-task');

    await expect(page.locator('#screen-manage')).toHaveClass(/active/);
    await expect(page.locator('.task-item-name')).toHaveText('Updated Task');
  });

  test('deletes task from edit screen', async ({ page }) => {
    await page.click('#btn-manage-tasks');
    await page.click('.task-item');

    page.on('dialog', dialog => dialog.accept());
    await page.click('#btn-delete-task');

    await expect(page.locator('#screen-manage')).toHaveClass(/active/);
    await expect(page.locator('#no-tasks-yet')).not.toHaveClass(/hidden/);
  });
});

test.describe('Templates', () => {
  test('saves and uses template', async ({ page }) => {
    // Create task with template checkbox
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Creative');
    await page.click('.time-option >> text=1 hour+');
    await page.click('#screen-add-social .level-option >> text=Low');
    await page.click('#screen-add-energy .level-option >> text=High');
    await page.fill('#task-name', 'Art Project');
    await page.check('#save-as-template');
    await page.click('#btn-next-to-schedule');
    await page.click('#btn-skip-schedule');

    // Start new task
    await page.click('#btn-add-task');

    // From Saved Tasks should be visible
    await expect(page.locator('#btn-from-template')).not.toHaveClass(/hidden/);
    await page.click('#btn-from-template');

    // Select template
    await expect(page.locator('#screen-templates')).toHaveClass(/active/);
    await page.click('.template-item');

    // Should go to details with pre-filled name
    await expect(page.locator('#screen-add-details')).toHaveClass(/active/);
    await expect(page.locator('#task-name')).toHaveValue('Art Project');
  });
});

test.describe('Multi-Add', () => {
  test('creates multiple tasks at once', async ({ page }) => {
    await page.click('#btn-add-task');
    await page.click('#btn-multi-add');

    // Select type
    await page.click('#multi-task-types .type-option >> text=Errand');

    // Select time
    await page.click('.multi-time-option >> text=15 min');

    // Select social
    await page.click('.multi-social-option >> text=Medium');

    // Select energy
    await page.click('.multi-energy-option >> text=Low');

    // Enter task names
    const inputs = page.locator('.multi-task-name');
    await inputs.nth(0).fill('Buy groceries');
    await inputs.nth(1).fill('Pick up dry cleaning');
    await inputs.nth(2).fill('Return package');
    // Leave 4 and 5 empty

    await page.click('#btn-save-multi');

    // Verify tasks created
    await page.click('#btn-manage-tasks');
    await expect(page.locator('.task-item')).toHaveCount(3);
  });
});

test.describe('Import', () => {
  test('imports tasks from plain text', async ({ page }) => {
    await page.click('#btn-add-task');
    await page.click('#btn-import');

    // Paste task list
    await page.fill('#import-text', `- Task One
- Task Two
* Task Three
1. Task Four`);

    await page.click('#btn-parse-import');

    // Should show review screen
    await expect(page.locator('#screen-import-review')).toHaveClass(/active/);
    await expect(page.locator('#import-count')).toHaveText('4');
    await expect(page.locator('.pending-import-item')).toHaveCount(4);

    // Setup first task
    await page.click('.pending-setup-btn >> nth=0');
    await expect(page.locator('#screen-import-setup')).toHaveClass(/active/);

    await page.click('#import-task-types .type-option >> text=Chores');
    await page.click('.import-time-option >> text=5 min');
    await page.click('.import-social-option >> text=Low');
    await page.click('.import-energy-option >> text=Low');

    await expect(page.locator('#btn-save-import-task')).not.toBeDisabled();
    await page.click('#btn-save-import-task');

    // Back to review with one less pending
    await expect(page.locator('#screen-import-review')).toHaveClass(/active/);
    await expect(page.locator('.pending-import-item')).toHaveCount(3);
  });
});

test.describe('Gallery', () => {
  test('shows empty state when no completed tasks', async ({ page }) => {
    await page.click('#btn-gallery');
    await expect(page.locator('#screen-gallery')).toHaveClass(/active/);
    await expect(page.locator('#no-completed')).not.toHaveClass(/hidden/);
  });

  test('shows completed tasks after completion', async ({ page }) => {
    // Create and complete a task
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Chores');
    await page.click('.time-option >> text=5 min');
    await page.click('#screen-add-social .level-option >> text=Low');
    await page.click('#screen-add-energy .level-option >> text=Low');
    await page.fill('#task-name', 'Test Chore');
    await page.click('#btn-next-to-schedule');
    await page.click('#btn-skip-schedule');

    // Complete task
    await page.click('#btn-what-next');
    await page.click('.state-btn[data-type="energy"][data-value="low"]');
    await page.click('.state-btn[data-type="social"][data-value="low"]');
    await page.click('.state-btn[data-type="time"][data-value="5"]');
    await page.click('#btn-find-task');

    const card = page.locator('.swipe-card').first();
    await card.dragTo(card, {
      sourcePosition: { x: 50, y: 200 },
      targetPosition: { x: 300, y: 200 },
    });

    await page.click('#btn-done');
    await page.click('#btn-celebration-done');

    // Check gallery
    await page.click('#btn-gallery');
    await expect(page.locator('#gallery-total-tasks')).toHaveText('1');
    await expect(page.locator('.gallery-item')).toHaveCount(1);
    await expect(page.locator('.gallery-item')).toContainText('Test Chore');
  });
});

test.describe('Offline Mode', () => {
  test('app works offline after initial load', async ({ page, context }) => {
    // Load page first
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Go offline
    await context.setOffline(true);

    // Reload
    await page.reload();

    // App should still work
    await expect(page.locator('.app-title')).toHaveText('What Now?');
    await expect(page.locator('#btn-add-task')).toBeVisible();
  });
});
