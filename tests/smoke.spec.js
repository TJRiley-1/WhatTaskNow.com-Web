// Smoke test - check for console errors and basic functionality
const { test, expect } = require('@playwright/test');

// Helper to clear state and skip onboarding
async function resetApp(page) {
  await page.evaluate(() => {
    localStorage.clear();
    localStorage.setItem('whatnow_onboarding_complete', 'true');
  });
  await page.reload();
  await page.waitForSelector('#screen-home.active', { timeout: 5000 });
}

test.describe('Smoke Tests', () => {
  test('no console errors on page load', async ({ page }) => {
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    page.on('pageerror', err => {
      errors.push(err.message);
    });

    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('whatnow_onboarding_complete', 'true');
    });
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Filter out expected errors (like service worker on localhost)
    const realErrors = errors.filter(e =>
      !e.includes('service worker') &&
      !e.includes('Failed to load resource')
    );

    expect(realErrors).toEqual([]);
  });

  test('all screens can be accessed', async ({ page }) => {
    await page.goto('/');
    await resetApp(page);

    // Home screen
    await expect(page.locator('#screen-home')).toHaveClass(/active/);

    // Add Task flow
    await page.click('#btn-add-task');
    await expect(page.locator('#screen-add-type')).toHaveClass(/active/);
    await page.click('#screen-add-type .btn-back');

    // What Next flow
    await page.click('#btn-what-next');
    await expect(page.locator('#screen-state')).toHaveClass(/active/);
    await page.click('#screen-state .btn-back');

    // Manage Tasks
    await page.click('#btn-manage-tasks');
    await expect(page.locator('#screen-manage')).toHaveClass(/active/);
    await page.click('#screen-manage .btn-back');

    // Gallery (via bottom nav)
    await page.click('.nav-item[data-screen="gallery"]');
    await expect(page.locator('#screen-gallery')).toHaveClass(/active/);
    await page.click('#screen-gallery .btn-back');

    // Profile (via bottom nav)
    await page.click('.nav-item[data-screen="profile"]');
    await expect(page.locator('#screen-profile')).toHaveClass(/active/);
  });

  test('profile shows guest state when not logged in', async ({ page }) => {
    await page.goto('/');
    await resetApp(page);

    await page.click('.nav-item[data-screen="profile"]');
    await expect(page.locator('#profile-name')).toHaveText('Guest');
    await expect(page.locator('#profile-email')).toHaveText('Not signed in');
    await expect(page.locator('#btn-login-from-profile')).toBeVisible();
  });

  test('login screen accessible from profile', async ({ page }) => {
    await page.goto('/');
    await resetApp(page);

    await page.click('.nav-item[data-screen="profile"]');
    await page.click('#btn-login-from-profile');
    await expect(page.locator('#screen-login')).toHaveClass(/active/);
    await expect(page.locator('#btn-google-login')).toBeVisible();
    await expect(page.locator('#btn-email-login')).toBeVisible();
  });

  test('groups screen accessible', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('whatnow_onboarding_complete', 'true');
    });
    await page.reload();
    await page.waitForSelector('#screen-home.active', { timeout: 5000 });
    await page.click('.nav-item[data-screen="profile"]');
    await page.click('#btn-view-groups');
    await expect(page.locator('#screen-groups')).toHaveClass(/active/);
  });

  test('import flow works', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('whatnow_onboarding_complete', 'true');
    });
    await page.reload();
    await page.waitForSelector('#screen-home.active', { timeout: 5000 });
    await page.click('#btn-add-task');
    await page.click('#btn-import');
    await expect(page.locator('#screen-import')).toHaveClass(/active/);
    await expect(page.locator('#import-text')).toBeVisible();
  });

  test('multi-add flow works', async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.setItem('whatnow_onboarding_complete', 'true');
    });
    await page.reload();
    await page.waitForSelector('#screen-home.active', { timeout: 5000 });
    await page.click('#btn-add-task');
    await page.click('#btn-multi-add');
    await expect(page.locator('#screen-multi-type')).toHaveClass(/active/);
  });

  test('full task lifecycle with points', async ({ page }) => {
    await page.goto('/');
    await resetApp(page);

    // Create task
    await page.click('#btn-add-task');
    await page.click('.type-option >> text=Chores');
    await page.click('.time-option >> text=5 min');
    await page.click('#screen-add-social .level-option >> text=Low');
    await page.click('#screen-add-energy .level-option >> text=Low');
    await page.fill('#task-name', 'Test Task');
    await page.click('#btn-next-to-schedule');
    await page.click('#btn-skip-schedule');

    // Complete task
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

    // Mark done
    await page.click('#btn-done');

    // Check celebration
    await expect(page.locator('#screen-celebration')).toHaveClass(/active/);
    await expect(page.locator('.points-earned')).toContainText('+15'); // 5 time + 5 social + 5 energy

    // Continue
    await page.click('#btn-celebration-done');

    // Check rank display is visible
    await expect(page.locator('#rank-display')).not.toHaveClass(/hidden/);
    await expect(page.locator('.rank-title')).toHaveText('Task Newbie');

    // Check gallery has the task
    await page.click('.nav-item[data-screen="gallery"]');
    await expect(page.locator('.gallery-item')).toHaveCount(1);
    await expect(page.locator('#gallery-total-tasks')).toHaveText('1');
    await expect(page.locator('#gallery-total-points')).toHaveText('15');
  });
});
