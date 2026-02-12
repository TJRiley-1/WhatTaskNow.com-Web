// @ts-check
const { test, expect } = require('@playwright/test');

// Helper: create a task quickly via the UI
async function createTask(page, { name, type = 'Chores', time = '5 min', social = 'Low', energy = 'Low', dueDate = null, recurring = null } = {}) {
  await page.click('#btn-add-task');
  await page.click(`.type-option >> text=${type}`);
  await page.click(`.time-option >> text=${time}`);
  await page.click(`#screen-add-social .level-option >> text=${social}`);
  await page.click(`#screen-add-energy .level-option >> text=${energy}`);
  await page.fill('#task-name', name);
  await page.click('#btn-next-to-schedule');

  if (dueDate) {
    await page.fill('#task-due-date', dueDate);
  }
  if (recurring) {
    await page.click(`.recurring-option >> text=${recurring}`);
    await page.click('#btn-save-task');
  } else {
    await page.click('#btn-skip-schedule');
  }
}

// Helper: navigate to What Next, select filters, find task, accept via swipe
async function acceptTask(page, { energy = 'low', social = 'low', time = '5' } = {}) {
  await page.click('#btn-what-next');
  await page.click(`.state-btn[data-type="energy"][data-value="${energy}"]`);
  await page.click(`.state-btn[data-type="social"][data-value="${social}"]`);
  await page.click(`.state-btn[data-type="time"][data-value="${time}"]`);
  await page.click('#btn-find-task');

  const card = page.locator('.swipe-card').first();
  await card.dragTo(card, {
    sourcePosition: { x: 50, y: 200 },
    targetPosition: { x: 300, y: 200 },
  });
}

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  await page.evaluate(() => {
    localStorage.clear();
    localStorage.setItem('whatnow_onboarding_complete', 'true');
    localStorage.setItem('whatnow_minitutorial_manage', 'true');
    localStorage.setItem('whatnow_minitutorial_whatnext', 'true');
  });
  await page.reload();
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('#screen-home.active', { timeout: 10000 });
});

// ─── Issue 1: Time filter uses exact match (===) not less-than-or-equal ───

test.describe('Issue 1: Time filter exact match', () => {
  test('filter labels do not show ≤ prefix', async ({ page }) => {
    await page.click('#btn-manage-tasks');
    const options = page.locator('#filter-time option');
    const texts = await options.allTextContents();
    // None of the options should contain ≤
    for (const text of texts) {
      expect(text).not.toContain('≤');
    }
    // Verify exact labels
    expect(texts).toContain('5 min');
    expect(texts).toContain('15 min');
    expect(texts).toContain('30 min');
    expect(texts).toContain('60 min');
  });

  test('selecting 15 min filter shows only 15-min tasks, not 5-min', async ({ page }) => {
    await createTask(page, { name: 'Quick 5min', time: '5 min' });
    await createTask(page, { name: 'Medium 15min', time: '15 min' });
    await createTask(page, { name: 'Long 30min', time: '30 min' });

    await page.click('#btn-manage-tasks');

    // Select 15 min filter
    await page.selectOption('#filter-time', '15');

    // Should only show the 15-min task
    const items = page.locator('.task-item');
    await expect(items).toHaveCount(1);
    await expect(items.first().locator('.task-item-name')).toHaveText('Medium 15min');
  });

  test('selecting 5 min filter shows only 5-min tasks', async ({ page }) => {
    await createTask(page, { name: 'Quick 5min', time: '5 min' });
    await createTask(page, { name: 'Medium 15min', time: '15 min' });

    await page.click('#btn-manage-tasks');
    await page.selectOption('#filter-time', '5');

    const items = page.locator('.task-item');
    await expect(items).toHaveCount(1);
    await expect(items.first().locator('.task-item-name')).toHaveText('Quick 5min');
  });
});

// ─── Issue 2: Delete confirmation on manage tasks page ───

test.describe('Issue 2: Delete confirmation on manage tasks', () => {
  test('clicking × shows confirm dialog, accepting deletes task', async ({ page }) => {
    await createTask(page, { name: 'Task To Delete' });
    await page.click('#btn-manage-tasks');

    // Accept the confirm dialog
    page.on('dialog', dialog => {
      expect(dialog.message()).toContain('Are you sure');
      dialog.accept();
    });

    await page.click('.task-item-delete');

    // Task should be deleted
    await expect(page.locator('#no-tasks-yet')).not.toHaveClass(/hidden/);
  });

  test('clicking × and dismissing confirm does NOT delete task', async ({ page }) => {
    await createTask(page, { name: 'Task To Keep' });
    await page.click('#btn-manage-tasks');

    // Dismiss the confirm dialog
    page.on('dialog', dialog => dialog.dismiss());

    await page.click('.task-item-delete');

    // Task should still be there
    await expect(page.locator('.task-item')).toHaveCount(1);
    await expect(page.locator('.task-item-name')).toHaveText('Task To Keep');
  });
});

// ─── Issue 3: Start button works from manage tasks ───

test.describe('Issue 3: Start button from manage tasks', () => {
  test('clicking Start on manage screen shows accepted screen', async ({ page }) => {
    await createTask(page, { name: 'Startable Task' });
    await page.click('#btn-manage-tasks');

    // Click the start button
    await page.click('.task-start-btn');

    // Should navigate to accepted screen
    await expect(page.locator('#screen-accepted')).toHaveClass(/active/);

    // Task name should be visible in accepted screen
    await expect(page.locator('#accepted-task .task-name')).toHaveText('Startable Task');
  });

  test('Start from manage shows timer and done buttons', async ({ page }) => {
    await createTask(page, { name: 'Timer Task' });
    await page.click('#btn-manage-tasks');
    await page.click('.task-start-btn');

    await expect(page.locator('#btn-start-timer')).toBeVisible();
    await expect(page.locator('#btn-done')).toBeVisible();
  });
});

// ─── Issue 5: Calendar view has Start and Delete buttons ───

test.describe('Issue 5: Calendar Start and Delete buttons', () => {
  test('calendar items have Start and Delete buttons', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'Calendar Task', dueDate: dateStr, recurring: 'None' });

    await page.click('.nav-item[data-screen="calendar"]');

    const calItem = page.locator('.calendar-item').first();
    await expect(calItem.locator('.task-start-btn')).toBeVisible();
    await expect(calItem.locator('.task-item-delete')).toBeVisible();
  });

  test('Start button in calendar opens accepted screen', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'Cal Start Task', dueDate: dateStr, recurring: 'None' });

    await page.click('.nav-item[data-screen="calendar"]');
    await page.click('.calendar-item .task-start-btn');

    await expect(page.locator('#screen-accepted')).toHaveClass(/active/);
    await expect(page.locator('#accepted-task .task-name')).toHaveText('Cal Start Task');
  });

  test('Delete button in calendar removes task after confirmation', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'Cal Delete Task', dueDate: dateStr, recurring: 'None' });

    await page.click('.nav-item[data-screen="calendar"]');
    await expect(page.locator('.calendar-item')).toHaveCount(1);

    // Accept confirm dialog
    page.on('dialog', dialog => dialog.accept());
    await page.click('.calendar-item .task-item-delete');

    // Task should be removed from calendar
    await expect(page.locator('#no-upcoming')).not.toHaveClass(/hidden/);
  });

  test('Clicking calendar item body still opens edit', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'Cal Edit Task', dueDate: dateStr, recurring: 'None' });

    await page.click('.nav-item[data-screen="calendar"]');
    // Click on the content area (not the buttons)
    await page.click('.calendar-item-content');

    await expect(page.locator('#screen-edit-task')).toHaveClass(/active/);
    await expect(page.locator('#edit-task-name')).toHaveValue('Cal Edit Task');
  });
});

// ─── Issue 6: Time spent metric records estimated time when no timer used ───

test.describe('Issue 6: Time spent without timer', () => {
  test('completing task without timer records estimated time', async ({ page }) => {
    await createTask(page, { name: 'No Timer Task', time: '15 min' });

    await acceptTask(page, { time: '15' });

    // Mark done without starting timer
    await page.click('#btn-done');
    await page.click('#btn-celebration-done');

    // Check gallery shows time spent
    await page.click('.nav-item[data-screen="gallery"]');
    const timeText = await page.locator('#gallery-total-time').textContent();
    // Should show 15m (the task's estimated time)
    expect(timeText).toContain('15m');
  });

  test('completing task with timer records actual timer time', async ({ page }) => {
    await createTask(page, { name: 'Timer Task' });

    await acceptTask(page);

    // Start timer and wait
    await page.click('#btn-start-timer');
    await page.waitForTimeout(2500);
    await page.click('#btn-timer-done');
    await page.click('#btn-celebration-done');

    // Check gallery shows time spent (should be 1m since timer rounds up)
    await page.click('.nav-item[data-screen="gallery"]');
    const timeText = await page.locator('#gallery-total-time').textContent();
    expect(timeText).toMatch(/\d+m/);
  });

  test('completed task in gallery shows time value', async ({ page }) => {
    await createTask(page, { name: 'Gallery Time Task', time: '30 min', energy: 'Medium', social: 'Medium' });

    await acceptTask(page, { energy: 'medium', social: 'medium', time: '30' });
    await page.click('#btn-done');
    await page.click('#btn-celebration-done');

    // Check the completed task entry includes time
    await page.click('.nav-item[data-screen="gallery"]');
    const completed = await page.evaluate(() =>
      JSON.parse(localStorage.getItem('whatnow_completed') || '[]')
    );
    expect(completed.length).toBe(1);
    expect(completed[0].timeSpent).toBe(30);
  });
});

// ─── Issue 7: Notification click goes to accepted screen (not edit) ───

test.describe('Issue 7: Notification click starts task', () => {
  test('clicking notification item opens accepted screen', async ({ page }) => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateStr = yesterday.toISOString().split('T')[0];

    await createTask(page, { name: 'Overdue Notify Task', dueDate: dateStr, recurring: 'None' });

    // Trigger notification badge update
    await page.click('#btn-manage-tasks');
    await page.click('#screen-manage .btn-back');

    // Open notifications
    await page.click('#floating-notification-bell');
    await expect(page.locator('#screen-notifications')).toHaveClass(/active/);

    // Click the notification item
    const notifItem = page.locator('.notification-item[data-task-id]').first();
    await expect(notifItem).toBeVisible();
    await notifItem.click();

    // Should go to accepted screen (not edit screen)
    await expect(page.locator('#screen-accepted')).toHaveClass(/active/);
    await expect(page.locator('#accepted-task .task-name')).toHaveText('Overdue Notify Task');

    // Timer and Done buttons should be available
    await expect(page.locator('#btn-start-timer')).toBeVisible();
    await expect(page.locator('#btn-done')).toBeVisible();
  });
});

// ─── Issue 9: Non-recurring due-date task removed after completion ───

test.describe('Issue 9: Non-recurring task with due date removed on completion', () => {
  test('completing a non-recurring task with due date removes it from task list', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'One-time Due Task', dueDate: dateStr, recurring: 'None' });

    // Verify task exists in manage
    await page.click('#btn-manage-tasks');
    await expect(page.locator('.task-item')).toHaveCount(1);
    await page.click('#screen-manage .btn-back');

    // Start from calendar and complete
    await page.click('.nav-item[data-screen="calendar"]');
    await page.click('.calendar-item .task-start-btn');
    await expect(page.locator('#screen-accepted')).toHaveClass(/active/);
    await page.click('#btn-done');
    await expect(page.locator('#screen-celebration')).toHaveClass(/active/);
    await page.click('#btn-celebration-done');

    // Task should be gone from manage tasks
    await page.click('#btn-manage-tasks');
    await expect(page.locator('#no-tasks-yet')).not.toHaveClass(/hidden/);

    // But should appear in completed history
    const completed = await page.evaluate(() =>
      JSON.parse(localStorage.getItem('whatnow_completed') || '[]')
    );
    expect(completed.length).toBe(1);
    expect(completed[0].name).toBe('One-time Due Task');
  });

  test('completing a non-recurring task WITHOUT due date keeps it in task list', async ({ page }) => {
    await createTask(page, { name: 'Reusable Task' });

    await acceptTask(page);
    await page.click('#btn-done');
    await page.click('#btn-celebration-done');

    // Task should still be in manage tasks (reusable)
    await page.click('#btn-manage-tasks');
    await expect(page.locator('.task-item')).toHaveCount(1);
    await expect(page.locator('.task-item-name')).toHaveText('Reusable Task');
  });

  test('completing a recurring task with due date keeps it and advances date', async ({ page }) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await createTask(page, { name: 'Weekly Task', dueDate: dateStr, recurring: 'Weekly' });

    await acceptTask(page);
    await page.click('#btn-done');
    await page.click('#btn-celebration-done');

    // Task should still be in manage tasks with advanced date
    await page.click('#btn-manage-tasks');
    await expect(page.locator('.task-item')).toHaveCount(1);
    await expect(page.locator('.task-item-name')).toHaveText('Weekly Task');
  });
});
