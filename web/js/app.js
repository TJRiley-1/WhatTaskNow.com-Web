// What Now? App - Main Application Logic

const App = {
    // Current state
    currentScreen: 'home',
    newTask: {},
    editingTask: null,
    editTaskOriginal: null,
    fromTemplate: false,
    multiAddTask: {},
    currentImportTask: null,
    importTaskSettings: {},
    currentState: {
        energy: null,
        social: null,
        time: null
    },
    matchingTasks: [],
    currentCardIndex: 0,
    acceptedTask: null,
    timerInterval: null,
    timerSeconds: 0,
    timerRunning: false,
    lastPointsEarned: 0,
    previousRank: null,

    // Auth state
    isLoggedIn: false,
    user: null,
    profile: null,
    currentGroup: null,

    // Onboarding state
    tutorialStep: 0,
    tutorialReviewMode: false,

    // Swipe cleanup function
    swipeCleanup: null,

    // Pending action (for resuming after login redirect)
    pendingAction: null,

    // Cached notification count (invalidated when tasks change)
    _notificationCache: null,
    _notificationCacheTime: 0,

    // Initialize the app
    async init() {
        this.bindEvents();
        this.bindBottomNavEvents();
        this.bindNotificationEvents();
        this.renderTaskTypes();
        this.renderEditTaskTypes();
        this.updateRankDisplay();

        // Initialize notification manager
        if (typeof NotificationManager !== 'undefined') {
            NotificationManager.init();
        }

        // Check if we just came back from OAuth (hash contains access_token)
        const isOAuthCallback = window.location.hash && window.location.hash.includes('access_token');
        const isRecovery = window.location.hash && window.location.hash.includes('type=recovery');

        // Initialize Supabase and check auth
        try {
            const user = await Supabase.init();
            if (user) {
                this.isLoggedIn = true;
                this.user = user;
                await this.loadProfile();
            }
        } catch (e) {
            console.log('Auth init error:', e);
        }

        this.updateAuthUI();

        // Handle password recovery redirect
        if (isRecovery && this.isLoggedIn) {
            this.showScreen('reset-password');
            return;
        }

        // Check if onboarding is complete
        if (!this.isOnboardingComplete()) {
            // If user just signed in via OAuth during onboarding, go to tutorial
            if (isOAuthCallback && this.isLoggedIn) {
                this.tutorialReviewMode = false;
                this.tutorialStep = 0;
                this.updateTutorialUI();
                this.showScreen('tutorial');
            } else {
                this.showScreen('welcome');
            }
        } else {
            // Check for pending action after OAuth callback
            if (isOAuthCallback && this.isLoggedIn) {
                const hadPendingAction = await this.checkPendingAction();
                if (!hadPendingAction) {
                    this.showScreen('home');
                }
            } else {
                this.showScreen('home');
            }
        }
    },

    // Check if onboarding has been completed
    isOnboardingComplete() {
        return localStorage.getItem('whatnow_onboarding_complete') === 'true';
    },

    // Mark onboarding as complete
    completeOnboarding() {
        localStorage.setItem('whatnow_onboarding_complete', 'true');
    },

    // Screens where bottom nav should be hidden
    hideNavScreens: ['login', 'welcome', 'tutorial', 'install-prompt', 'swipe', 'accepted', 'timer', 'celebration', 'forgot-password', 'reset-password'],

    // Screen navigation
    showScreen(screenId) {
        // Clean up swipe listeners when leaving swipe screen
        if (this.currentScreen === 'swipe' && screenId !== 'swipe') {
            this.cleanupSwipe();
        }

        const screens = document.querySelectorAll('.screen');
        screens.forEach(screen => {
            if (screen.id === `screen-${screenId}`) {
                screen.classList.add('active');
                screen.classList.remove('exiting');
            } else if (screen.classList.contains('active')) {
                screen.classList.add('exiting');
                screen.classList.remove('active');
            } else {
                screen.classList.remove('exiting');
            }
        });
        this.currentScreen = screenId;

        // Screen-specific setup
        if (screenId === 'manage') {
            this.renderTaskList();
            this.showMiniTutorial('manage', 'Manage Your Tasks',
                'Tap a task to edit it, use the × to delete, or hit <strong>Start</strong> to jump right into it. Use the filters at the top to find tasks by time, energy, or social level.');
        } else if (screenId === 'notifications') {
            this.renderNotifications();
        } else if (screenId === 'calendar') {
            this.renderCalendar();
        } else if (screenId === 'state') {
            this.showMiniTutorial('whatnext', 'How "What Next" Works',
                'Tell the app how you\'re feeling — pick your <strong>energy level</strong>, <strong>social battery</strong>, and how much <strong>time</strong> you have. Tap an option to select it, tap again to deselect. Then hit Find Task to get matched suggestions!');
        }

        // Update bottom nav visibility and active state
        this.updateBottomNav(screenId);
    },

    // Clean up swipe event listeners
    cleanupSwipe() {
        if (this.swipeCleanup) {
            this.swipeCleanup();
            this.swipeCleanup = null;
        }
    },

    // Event binding
    bindEvents() {
        // Home screen buttons
        document.getElementById('btn-add-task').addEventListener('click', () => {
            this.newTask = {};
            this.fromTemplate = false;
            this.updateTemplateButtonVisibility();
            this.showScreen('add-type');
        });

        document.getElementById('btn-what-next').addEventListener('click', () => {
            this.resetCurrentState();
            this.showScreen('state');
        });

        document.getElementById('btn-manage-tasks').addEventListener('click', () => {
            this.showScreen('manage');
        });

        // Back buttons
        document.querySelectorAll('.btn-back').forEach(btn => {
            btn.addEventListener('click', () => {
                const target = btn.dataset.back;
                this.showScreen(target);
            });
        });

        // Task type selection
        document.getElementById('task-types').addEventListener('click', (e) => {
            if (e.target.classList.contains('type-option')) {
                this.newTask.type = e.target.dataset.value;
                this.showScreen('add-time');
            }
        });

        // Add custom type
        document.getElementById('btn-add-custom-type').addEventListener('click', () => {
            document.getElementById('modal-custom-type').classList.remove('hidden');
            document.getElementById('custom-type-input').focus();
        });

        document.getElementById('btn-cancel-type').addEventListener('click', () => {
            document.getElementById('modal-custom-type').classList.add('hidden');
            document.getElementById('custom-type-input').value = '';
        });

        document.getElementById('btn-confirm-type').addEventListener('click', () => {
            const input = document.getElementById('custom-type-input');
            const typeName = input.value.trim();
            if (typeName) {
                Storage.addTaskType(typeName);
                this.renderTaskTypes();
                input.value = '';
                document.getElementById('modal-custom-type').classList.add('hidden');
            }
        });

        // From template button
        document.getElementById('btn-from-template').addEventListener('click', () => {
            this.renderTemplateList();
            this.showScreen('templates');
        });

        // Multi-add button
        document.getElementById('btn-multi-add').addEventListener('click', () => {
            this.multiAddTask = {};
            this.renderMultiTaskTypes();
            this.showScreen('multi-type');
        });

        // Import button
        document.getElementById('btn-import').addEventListener('click', () => {
            document.getElementById('import-text').value = '';
            this.showScreen('import');
        });

        // Time selection
        document.querySelectorAll('.time-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.newTask.time = parseInt(btn.dataset.value);
                this.showScreen('add-social');
            });
        });

        // Social battery selection (Add Task)
        document.getElementById('screen-add-social').querySelectorAll('.level-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.newTask.social = btn.dataset.value;
                this.showScreen('add-energy');
            });
        });

        // Energy level selection (Add Task)
        document.getElementById('screen-add-energy').querySelectorAll('.level-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.newTask.energy = btn.dataset.value;
                this.showScreen('add-details');
            });
        });

        // Next to schedule step
        document.getElementById('btn-next-to-schedule').addEventListener('click', () => {
            const name = document.getElementById('task-name').value.trim();
            if (name) {
                this.newTask.name = name;
                this.newTask.desc = document.getElementById('task-desc').value.trim();
                // Reset schedule options
                document.getElementById('task-due-date').value = '';
                document.querySelectorAll('.recurring-option').forEach(btn => {
                    btn.classList.toggle('selected', btn.dataset.value === 'none');
                });
                this.newTask.recurring = 'none';
                this.showScreen('add-schedule');
            }
        });

        // Recurring option selection
        document.querySelectorAll('.recurring-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.recurring-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.newTask.recurring = btn.dataset.value;
            });
        });

        // Skip schedule
        document.getElementById('btn-skip-schedule').addEventListener('click', () => {
            this.saveNewTask();
        });

        // Save task (final step)
        document.getElementById('btn-save-task').addEventListener('click', () => {
            const dueDate = document.getElementById('task-due-date').value;
            if (dueDate) {
                this.newTask.dueDate = dueDate;
            }
            this.saveNewTask();
        });

        // State selection (What Next flow)
        document.querySelectorAll('.state-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const type = btn.dataset.type;
                const value = btn.dataset.value;

                // Toggle: if already selected, deselect
                if (btn.classList.contains('selected')) {
                    btn.classList.remove('selected');
                    this.currentState[type] = null;
                } else {
                    this.currentState[type] = type === 'time' ? parseInt(value) : value;
                    const row = btn.parentElement;
                    row.querySelectorAll('.state-btn').forEach(b => b.classList.remove('selected'));
                    btn.classList.add('selected');
                }

                // Enable find button if all selected
                this.updateFindButtonState();
            });
        });

        // Find task button
        document.getElementById('btn-find-task').addEventListener('click', () => {
            this.findAndShowTasks();
        });

        // Accepted task buttons
        document.getElementById('btn-start-timer').addEventListener('click', () => {
            this.startTimer();
        });

        document.getElementById('btn-done').addEventListener('click', () => {
            this.completeTask(false);
        });

        document.getElementById('btn-not-now').addEventListener('click', () => {
            // Skip this task and show the next card
            const task = this.acceptedTask;
            if (task && !task.isFallback) {
                const skipUpdates = {
                    timesShown: (task.timesShown || 0) + 1,
                    timesSkipped: (task.timesSkipped || 0) + 1
                };
                Storage.updateTask(task.id, skipUpdates);
                this.syncToCloud('update', task, skipUpdates);
            }
            this.acceptedTask = null;
            this.currentCardIndex++;
            this.showScreen('swipe');
            this.renderCards();
        });

        // Timer controls
        document.getElementById('btn-timer-pause').addEventListener('click', () => {
            this.toggleTimer();
        });

        document.getElementById('btn-timer-done').addEventListener('click', () => {
            this.completeTask(true);
        });

        document.getElementById('btn-timer-cancel').addEventListener('click', () => {
            this.cancelTimer();
            this.showScreen('accepted');
        });

        // Celebration continue
        document.getElementById('btn-celebration-done').addEventListener('click', () => {
            this.updateRankDisplay();
            this.showScreen('home');
        });

        // No tasks back button
        document.querySelector('#no-tasks-message .btn').addEventListener('click', () => {
            this.showScreen('home');
        });

        // Edit task screen events
        this.bindEditTaskEvents();

        // Multi-add events
        this.bindMultiAddEvents();

        // Import events
        this.bindImportEvents();

        // Auth and social events
        this.bindAuthEvents();

        // Onboarding events
        this.bindOnboardingEvents();
    },

    // Bind onboarding events
    bindOnboardingEvents() {
        // Welcome screen - Google sign in
        document.getElementById('btn-welcome-google').addEventListener('click', () => {
            Supabase.signInWithGoogle();
        });

        // Welcome screen - Continue as guest
        document.getElementById('btn-welcome-guest').addEventListener('click', () => {
            this.tutorialReviewMode = false;
            this.tutorialStep = 0;
            this.updateTutorialUI();
            this.showScreen('tutorial');
        });

        // Tutorial - Skip button
        document.getElementById('btn-tutorial-skip').addEventListener('click', () => {
            this.finishTutorial();
        });

        // Tutorial - Back button
        document.getElementById('btn-tutorial-back').addEventListener('click', () => {
            if (this.tutorialStep > 0) {
                this.tutorialStep--;
                this.updateTutorialUI();
            }
        });

        // Tutorial - Next button
        document.getElementById('btn-tutorial-next').addEventListener('click', () => {
            if (this.tutorialStep < 3) {
                this.tutorialStep++;
                this.updateTutorialUI();
            } else {
                this.finishTutorial();
            }
        });

        // Install prompt - Done button
        document.getElementById('btn-install-done').addEventListener('click', () => {
            this.completeOnboarding();
            this.showScreen('home');
        });
    },

    // Update tutorial UI based on current step
    updateTutorialUI() {
        // Update dots
        document.querySelectorAll('.tutorial-dot').forEach((dot, index) => {
            dot.classList.toggle('active', index <= this.tutorialStep);
        });

        // Update cards
        document.querySelectorAll('.tutorial-card').forEach((card, index) => {
            card.classList.remove('active', 'exiting');
            if (index === this.tutorialStep) {
                card.classList.add('active');
            } else if (index < this.tutorialStep) {
                card.classList.add('exiting');
            }
        });

        // Update buttons
        document.getElementById('btn-tutorial-back').disabled = this.tutorialStep === 0;
        document.getElementById('btn-tutorial-skip').textContent = this.tutorialReviewMode ? 'Close' : 'Skip';

        if (this.tutorialStep === 3) {
            document.getElementById('btn-tutorial-next').textContent = this.tutorialReviewMode ? 'Done' : 'Get Started';
        } else {
            document.getElementById('btn-tutorial-next').textContent = 'Next';
        }
    },

    // Open tutorial from profile (review mode)
    openTutorialFromProfile() {
        this.tutorialReviewMode = true;
        this.tutorialStep = 0;
        this.updateTutorialUI();
        this.showScreen('tutorial');
    },

    // Finish tutorial - different behavior for review vs onboarding
    finishTutorial() {
        if (this.tutorialReviewMode) {
            this.tutorialReviewMode = false;
            this.showScreen('profile');
        } else {
            this.showInstallPrompt();
        }
    },

    // Show install prompt with platform detection
    showInstallPrompt() {
        const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
        const isAndroid = /Android/.test(navigator.userAgent);
        const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                           window.navigator.standalone === true;

        // Hide all instruction sets first
        document.getElementById('install-instructions-ios').classList.add('hidden');
        document.getElementById('install-instructions-android').classList.add('hidden');
        document.getElementById('install-instructions-desktop').classList.add('hidden');

        // Show platform-specific instructions
        if (isStandalone) {
            // Already installed
            document.getElementById('install-instructions-desktop').classList.remove('hidden');
        } else if (isIOS) {
            document.getElementById('install-instructions-ios').classList.remove('hidden');
        } else if (isAndroid) {
            document.getElementById('install-instructions-android').classList.remove('hidden');
        } else {
            // Desktop or unknown
            document.getElementById('install-instructions-desktop').classList.remove('hidden');
        }

        this.showScreen('install-prompt');
    },

    // Bind multi-add events
    bindMultiAddEvents() {
        // Multi-add type selection
        document.getElementById('multi-task-types').addEventListener('click', (e) => {
            if (e.target.classList.contains('type-option')) {
                this.multiAddTask.type = e.target.dataset.value;
                this.showScreen('multi-time');
            }
        });

        // Multi-add time selection
        document.querySelectorAll('.multi-time-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.multiAddTask.time = parseInt(btn.dataset.value);
                this.showScreen('multi-social');
            });
        });

        // Multi-add social selection
        document.querySelectorAll('.multi-social-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.multiAddTask.social = btn.dataset.value;
                this.showScreen('multi-energy');
            });
        });

        // Multi-add energy selection
        document.querySelectorAll('.multi-energy-option').forEach(btn => {
            btn.addEventListener('click', () => {
                this.multiAddTask.energy = btn.dataset.value;
                // Clear previous inputs
                document.querySelectorAll('.multi-task-name').forEach(input => {
                    input.value = '';
                });
                this.showScreen('multi-names');
            });
        });

        // Save all multi-add tasks
        document.getElementById('btn-save-multi').addEventListener('click', () => {
            this.saveMultiTasks();
        });
    },

    // Render task types for multi-add
    renderMultiTaskTypes() {
        const container = document.getElementById('multi-task-types');
        const types = Storage.getTaskTypes();

        container.innerHTML = types.map(type => `
            <button class="option-btn type-option" data-value="${type}">${type}</button>
        `).join('');
    },

    // Save multiple tasks
    saveMultiTasks() {
        const inputs = document.querySelectorAll('.multi-task-name');
        let savedCount = 0;

        inputs.forEach(input => {
            const name = input.value.trim();
            if (name) {
                const savedMultiTask = Storage.addTask({
                    name: name,
                    desc: '',
                    type: this.multiAddTask.type,
                    time: this.multiAddTask.time,
                    social: this.multiAddTask.social,
                    energy: this.multiAddTask.energy
                });
                this.syncToCloud('add', savedMultiTask);
                savedCount++;
            }
        });

        if (savedCount > 0) {
            // Clear inputs
            inputs.forEach(input => {
                input.value = '';
            });
            this.multiAddTask = {};
            this.showScreen('home');
        }
    },

    // Bind import events
    bindImportEvents() {
        // File upload
        document.getElementById('import-file').addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (event) => {
                    document.getElementById('import-text').value = event.target.result;
                };
                reader.readAsText(file);
            }
        });

        // Parse button
        document.getElementById('btn-parse-import').addEventListener('click', () => {
            this.parseImportText();
        });

        // Import task setup - back button
        document.getElementById('btn-import-setup-back').addEventListener('click', () => {
            this.renderPendingImports();
            this.showScreen('import-review');
        });

        // Import task types
        document.getElementById('import-task-types').addEventListener('click', (e) => {
            if (e.target.classList.contains('type-option')) {
                document.querySelectorAll('#import-task-types .type-option').forEach(btn => btn.classList.remove('selected'));
                e.target.classList.add('selected');
                this.importTaskSettings.type = e.target.dataset.value;
                this.updateImportSaveButton();
            }
        });

        // Import time selection
        document.querySelectorAll('.import-time-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.import-time-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.importTaskSettings.time = parseInt(btn.dataset.value);
                this.updateImportSaveButton();
            });
        });

        // Import social selection
        document.querySelectorAll('.import-social-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.import-social-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.importTaskSettings.social = btn.dataset.value;
                this.updateImportSaveButton();
            });
        });

        // Import energy selection
        document.querySelectorAll('.import-energy-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.import-energy-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.importTaskSettings.energy = btn.dataset.value;
                this.updateImportSaveButton();
            });
        });

        // Save import task
        document.getElementById('btn-save-import-task').addEventListener('click', () => {
            this.saveImportTask();
        });

        // Finish import
        document.getElementById('btn-finish-import').addEventListener('click', () => {
            this.showScreen('home');
        });
    },

    // Parse import text
    parseImportText() {
        const text = document.getElementById('import-text').value.trim();
        if (!text) return;

        // Detect format
        let tasks = [];
        if (text.includes(',') && text.split('\n')[0].includes(',')) {
            // Likely CSV
            tasks = Storage.parseCSV(text);
        } else {
            // Plain text or Apple Notes
            tasks = Storage.parseImportText(text);
        }

        if (tasks.length === 0) {
            return;
        }

        // Add to pending imports
        Storage.clearPendingImports();
        tasks.forEach(name => {
            Storage.addPendingImport(name);
        });

        this.renderPendingImports();
        this.showScreen('import-review');
    },

    // Render pending imports
    renderPendingImports() {
        const pending = Storage.getPendingImports();
        const container = document.getElementById('pending-import-list');
        const noImports = document.getElementById('no-pending-imports');
        const finishBtn = document.getElementById('btn-finish-import');

        document.getElementById('import-count').textContent = pending.length;

        if (pending.length === 0) {
            container.classList.add('hidden');
            noImports.classList.remove('hidden');
            finishBtn.classList.remove('hidden');
            return;
        }

        container.classList.remove('hidden');
        noImports.classList.add('hidden');
        finishBtn.classList.add('hidden');

        container.innerHTML = pending.map(item => `
            <div class="pending-import-item" data-id="${item.id}">
                <span class="pending-import-name">${this.escapeHtml(item.name)}</span>
                <div class="pending-import-actions">
                    <button class="btn btn-primary pending-setup-btn" data-id="${item.id}">Setup</button>
                    <button class="btn btn-outline pending-delete-btn" data-id="${item.id}">×</button>
                </div>
            </div>
        `).join('');

        // Use event delegation on the container
        if (!container._delegated) {
            container._delegated = true;
            container.addEventListener('click', (e) => {
                const setupBtn = e.target.closest('.pending-setup-btn');
                if (setupBtn) {
                    this.openImportSetup(setupBtn.dataset.id);
                    return;
                }
                const deleteBtn = e.target.closest('.pending-delete-btn');
                if (deleteBtn) {
                    Storage.removePendingImport(deleteBtn.dataset.id);
                    this.renderPendingImports();
                }
            });
        }
    },

    // Open import task setup
    openImportSetup(importId) {
        const pending = Storage.getPendingImports();
        const item = pending.find(p => p.id === importId);
        if (!item) return;

        this.currentImportTask = item;
        this.importTaskSettings = {};

        // Update UI
        document.getElementById('import-task-name').textContent = item.name;

        // Render types
        const typesContainer = document.getElementById('import-task-types');
        const types = Storage.getTaskTypes();
        typesContainer.innerHTML = types.map(type => `
            <button class="option-btn type-option" data-value="${type}">${type}</button>
        `).join('');

        // Clear selections
        document.querySelectorAll('.import-time-option, .import-social-option, .import-energy-option').forEach(btn => {
            btn.classList.remove('selected');
        });

        document.getElementById('btn-save-import-task').disabled = true;

        this.showScreen('import-setup');
    },

    // Update import save button state
    updateImportSaveButton() {
        const allSelected = this.importTaskSettings.type &&
                           this.importTaskSettings.time &&
                           this.importTaskSettings.social &&
                           this.importTaskSettings.energy;
        document.getElementById('btn-save-import-task').disabled = !allSelected;
    },

    // Save import task
    saveImportTask() {
        if (!this.currentImportTask) return;

        const savedImportTask = Storage.addTask({
            name: this.currentImportTask.name,
            desc: '',
            type: this.importTaskSettings.type,
            time: this.importTaskSettings.time,
            social: this.importTaskSettings.social,
            energy: this.importTaskSettings.energy
        });
        this.syncToCloud('add', savedImportTask);

        Storage.removePendingImport(this.currentImportTask.id);
        this.currentImportTask = null;
        this.importTaskSettings = {};

        this.renderPendingImports();
        this.showScreen('import-review');
    },

    // Bind edit task events
    bindEditTaskEvents() {
        // Back button with unsaved changes check
        document.getElementById('btn-edit-back').addEventListener('click', () => {
            if (this.hasUnsavedEditChanges()) {
                if (confirm('You have unsaved changes. Discard them?')) {
                    this.showScreen('manage');
                }
            } else {
                this.showScreen('manage');
            }
        });

        // Edit task type selection
        document.getElementById('edit-task-types').addEventListener('click', (e) => {
            if (e.target.classList.contains('type-option')) {
                document.querySelectorAll('#edit-task-types .type-option').forEach(btn => btn.classList.remove('selected'));
                e.target.classList.add('selected');
                this.editingTask.type = e.target.dataset.value;
            }
        });

        // Edit time selection
        document.querySelectorAll('.edit-time-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.edit-time-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.editingTask.time = parseInt(btn.dataset.value);
            });
        });

        // Edit social selection
        document.querySelectorAll('.edit-social-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.edit-social-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.editingTask.social = btn.dataset.value;
            });
        });

        // Edit energy selection
        document.querySelectorAll('.edit-energy-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.edit-energy-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.editingTask.energy = btn.dataset.value;
            });
        });

        // Edit recurring selection
        document.querySelectorAll('.edit-recurring-option').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.edit-recurring-option').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');
                this.editingTask.recurring = btn.dataset.value;
            });
        });

        // Save changes
        document.getElementById('btn-update-task').addEventListener('click', () => {
            const name = document.getElementById('edit-task-name').value.trim();
            if (name) {
                this.editingTask.name = name;
                this.editingTask.desc = document.getElementById('edit-task-desc').value.trim();
                this.editingTask.dueDate = document.getElementById('edit-task-due-date').value || null;
                Storage.updateTask(this.editingTask.id, this.editingTask);
                this.syncToCloud('update', this.editingTask, this.editingTask);
                this._notificationCache = null;
                this.showScreen('manage');
            }
        });

        // Delete task
        document.getElementById('btn-delete-task').addEventListener('click', () => {
            if (confirm('Delete this task?')) {
                const deletedId = this.editingTask.id;
                Storage.deleteTask(deletedId);
                this.syncToCloud('delete', deletedId);
                this._notificationCache = null;
                this.showScreen('manage');
            }
        });
    },

    // Check for unsaved changes in edit screen
    hasUnsavedEditChanges() {
        if (!this.editingTask || !this.editTaskOriginal) return false;
        const currentName = document.getElementById('edit-task-name').value.trim();
        const currentDesc = document.getElementById('edit-task-desc').value.trim();
        const currentDueDate = document.getElementById('edit-task-due-date').value || null;
        return currentName !== this.editTaskOriginal.name ||
               currentDesc !== (this.editTaskOriginal.desc || '') ||
               this.editingTask.type !== this.editTaskOriginal.type ||
               this.editingTask.time !== this.editTaskOriginal.time ||
               this.editingTask.social !== this.editTaskOriginal.social ||
               this.editingTask.energy !== this.editTaskOriginal.energy ||
               currentDueDate !== (this.editTaskOriginal.dueDate || null) ||
               this.editingTask.recurring !== (this.editTaskOriginal.recurring || 'none');
    },

    // Open edit task screen
    openEditTask(taskId) {
        const task = Storage.getTasks().find(t => t.id === taskId);
        if (!task) {
            // Show error and navigate back to manage
            const errorEl = document.getElementById('login-error');
            if (errorEl) {
                errorEl.textContent = 'Task not found. It may have been deleted.';
                errorEl.classList.remove('hidden');
            }
            this.showScreen('manage');
            return;
        }

        this.editingTask = { ...task };
        this.editTaskOriginal = { ...task };

        // Populate form
        document.getElementById('edit-task-name').value = task.name;
        document.getElementById('edit-task-desc').value = task.desc || '';

        // Select type
        this.renderEditTaskTypes();
        document.querySelectorAll('#edit-task-types .type-option').forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.value === task.type);
        });

        // Select time
        document.querySelectorAll('.edit-time-option').forEach(btn => {
            btn.classList.toggle('selected', parseInt(btn.dataset.value) === task.time);
        });

        // Select social
        document.querySelectorAll('.edit-social-option').forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.value === task.social);
        });

        // Select energy
        document.querySelectorAll('.edit-energy-option').forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.value === task.energy);
        });

        // Set due date
        document.getElementById('edit-task-due-date').value = task.dueDate || '';

        // Select recurring
        const recurring = task.recurring || 'none';
        document.querySelectorAll('.edit-recurring-option').forEach(btn => {
            btn.classList.toggle('selected', btn.dataset.value === recurring);
        });

        this.showScreen('edit-task');
    },

    // Render task types for edit screen
    renderEditTaskTypes() {
        const container = document.getElementById('edit-task-types');
        const types = Storage.getTaskTypes();

        container.innerHTML = types.map(type => `
            <button class="option-btn type-option" data-value="${type}">${type}</button>
        `).join('');
    },

    // Reset current state selections
    resetCurrentState() {
        this.currentState = { energy: null, social: null, time: null };
        document.querySelectorAll('.state-btn').forEach(btn => btn.classList.remove('selected'));
        document.getElementById('btn-find-task').disabled = true;
    },

    // Check if at least one state option is selected
    updateFindButtonState() {
        const anySelected = this.currentState.energy || this.currentState.social || this.currentState.time;
        document.getElementById('btn-find-task').disabled = !anySelected;
    },

    // Render task types
    renderTaskTypes() {
        const container = document.getElementById('task-types');
        const types = Storage.getTaskTypes();
        const defaults = ['Chores', 'Work', 'Health', 'Admin', 'Errand', 'Self-care', 'Creative', 'Social'];

        container.innerHTML = types.map(type => {
            const isCustom = !defaults.includes(type);
            if (isCustom) {
                return `<div class="type-option-wrapper">
                    <button class="option-btn type-option" data-value="${this.escapeHtml(type)}">${this.escapeHtml(type)}</button>
                    <button class="type-delete-btn" data-type="${this.escapeHtml(type)}" title="Delete custom type">×</button>
                </div>`;
            }
            return `<button class="option-btn type-option" data-value="${type}">${type}</button>`;
        }).join('');

        // Bind delete buttons for custom types
        container.querySelectorAll('.type-delete-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const typeName = btn.dataset.type;
                if (confirm(`Delete custom type "${typeName}"?`)) {
                    Storage.removeTaskType(typeName);
                    this.renderTaskTypes();
                }
            });
        });
    },

    // Update template button visibility
    updateTemplateButtonVisibility() {
        const templates = Storage.getTemplates();
        const btn = document.getElementById('btn-from-template');
        if (templates.length > 0) {
            btn.classList.remove('hidden');
        } else {
            btn.classList.add('hidden');
        }
    },

    // Render template list
    renderTemplateList() {
        const container = document.getElementById('template-list');
        const noTemplates = document.getElementById('no-templates');
        const templates = Storage.getTemplates();

        if (templates.length === 0) {
            container.classList.add('hidden');
            noTemplates.classList.remove('hidden');
            return;
        }

        container.classList.remove('hidden');
        noTemplates.classList.add('hidden');

        container.innerHTML = templates.map(template => `
            <div class="template-item" data-id="${template.id}">
                <div class="template-item-content">
                    <div class="template-item-name">${this.escapeHtml(template.name)}</div>
                    <div class="template-item-meta">
                        ${template.type} · ${template.time} min · Energy: ${template.energy} · Social: ${template.social}
                    </div>
                </div>
                <button class="template-item-delete" data-id="${template.id}">×</button>
            </div>
        `).join('');

        // Use event delegation on the container
        if (!container._delegated) {
            container._delegated = true;
            container.addEventListener('click', (e) => {
                const deleteBtn = e.target.closest('.template-item-delete');
                if (deleteBtn) {
                    e.stopPropagation();
                    Storage.deleteTemplate(deleteBtn.dataset.id);
                    this.renderTemplateList();
                    this.updateTemplateButtonVisibility();
                    return;
                }
                const item = e.target.closest('.template-item');
                if (item) {
                    this.useTemplate(item.dataset.id);
                }
            });
        }
    },

    // Use a template to pre-fill task
    useTemplate(templateId) {
        const templates = Storage.getTemplates();
        const template = templates.find(t => t.id === templateId);
        if (!template) return;

        // Pre-fill task with template data
        this.newTask = {
            type: template.type,
            time: template.time,
            social: template.social,
            energy: template.energy
        };
        this.fromTemplate = true;

        // Go directly to name/desc screen with pre-filled values
        document.getElementById('task-name').value = template.name;
        document.getElementById('task-desc').value = template.desc || '';

        this.showScreen('add-details');
    },

    // Save new task (called from schedule screen)
    saveNewTask() {
        const saveAsTemplate = document.getElementById('save-as-template').checked;

        this._notificationCache = null; // Invalidate badge cache
        const savedTask = Storage.addTask(this.newTask);
        this.syncToCloud('add', savedTask);

        // Save as template if checked
        if (saveAsTemplate) {
            Storage.addTemplate({
                name: this.newTask.name,
                desc: this.newTask.desc,
                type: this.newTask.type,
                time: this.newTask.time,
                social: this.newTask.social,
                energy: this.newTask.energy
            });
        }

        // Schedule notifications if task has due date
        if (savedTask.dueDate) {
            this.scheduleTaskNotifications(savedTask);

            // Prompt for notification permission if first task with due date
            if (this.shouldPromptForNotifications()) {
                this.showNotificationPrompt();
            }
        }

        // Clear form
        document.getElementById('task-name').value = '';
        document.getElementById('task-desc').value = '';
        document.getElementById('save-as-template').checked = false;
        document.getElementById('task-due-date').value = '';
        this.newTask = {};
        this.fromTemplate = false;

        this.showScreen('home');
    },

    // Render task list (Manage screen)
    renderTaskList() {
        const container = document.getElementById('task-list');
        const noTasks = document.getElementById('no-tasks-yet');
        let tasks = Storage.getTasks();

        // Apply filters
        const filterTime = document.getElementById('filter-time').value;
        const filterEnergy = document.getElementById('filter-energy').value;
        const filterSocial = document.getElementById('filter-social').value;
        const levelMap = { low: 1, medium: 2, high: 3 };

        if (filterTime) {
            tasks = tasks.filter(t => t.time === parseInt(filterTime));
        }
        if (filterEnergy) {
            tasks = tasks.filter(t => levelMap[t.energy] <= levelMap[filterEnergy]);
        }
        if (filterSocial) {
            tasks = tasks.filter(t => levelMap[t.social] <= levelMap[filterSocial]);
        }

        if (tasks.length === 0) {
            container.classList.add('hidden');
            noTasks.classList.remove('hidden');
            return;
        }

        container.classList.remove('hidden');
        noTasks.classList.add('hidden');

        container.innerHTML = tasks.map(task => {
            const isOverdue = Storage.isOverdue(task);
            const daysUntil = Storage.getDaysUntilDue(task);
            let dueInfo = '';
            if (daysUntil !== null) {
                if (isOverdue) {
                    dueInfo = '<div class="task-item-overdue">Overdue!</div>';
                } else if (daysUntil === 0) {
                    dueInfo = '<div class="task-item-overdue" style="color: var(--secondary)">Due today</div>';
                } else if (daysUntil === 1) {
                    dueInfo = '<div class="task-item-overdue" style="color: var(--secondary)">Due tomorrow</div>';
                } else if (daysUntil <= 7) {
                    dueInfo = `<div class="task-item-overdue" style="color: var(--text-muted)">Due in ${daysUntil} days</div>`;
                }
            }
            const recurringBadge = task.recurring && task.recurring !== 'none' ? ` · ${task.recurring}` : '';

            return `
                <div class="task-item${isOverdue ? ' overdue' : ''}" data-id="${task.id}">
                    <div class="task-item-content">
                        <div class="task-item-name">${this.escapeHtml(task.name)}</div>
                        <div class="task-item-meta">
                            ${task.type} · ${task.time} min · Energy: ${task.energy} · Social: ${task.social}${recurringBadge}
                        </div>
                        ${dueInfo}
                    </div>
                    <button class="task-start-btn" data-id="${task.id}">Start</button>
                    <button class="task-item-delete" data-id="${task.id}">×</button>
                </div>
            `;
        }).join('');

        // Use event delegation on the container (no per-item listeners)
        if (!container._delegated) {
            container._delegated = true;
            container.addEventListener('click', (e) => {
                const startBtn = e.target.closest('.task-start-btn');
                if (startBtn) {
                    e.stopPropagation();
                    const task = Storage.getTasks().find(t => t.id === startBtn.dataset.id);
                    if (task) {
                        this.acceptedTask = task;
                        this.showAcceptedTask();
                    }
                    return;
                }
                const deleteBtn = e.target.closest('.task-item-delete');
                if (deleteBtn) {
                    e.stopPropagation();
                    if (confirm('Are you sure you want to delete this task?')) {
                        Storage.deleteTask(deleteBtn.dataset.id);
                        this.syncToCloud('delete', deleteBtn.dataset.id);
                        this._notificationCache = null;
                        this.renderTaskList();
                    }
                    return;
                }
                const taskItem = e.target.closest('.task-item');
                if (taskItem) {
                    this.openEditTask(taskItem.dataset.id);
                }
            });
        }
    },

    // Find matching tasks and show swipe screen
    findAndShowTasks() {
        const { energy, social, time } = this.currentState;

        // Get matching user tasks
        let tasks = Storage.findMatchingTasks(energy, social, time);

        // If no user tasks, get fallback tasks
        if (tasks.length === 0) {
            tasks = Storage.getFallbackTasks(energy, social, time);
        }

        // Shuffle non-urgent tasks for variety, but keep urgent tasks at the front
        const urgent = tasks.filter(t => Storage.getUrgencyScore(t) >= 2);
        const nonUrgent = tasks.filter(t => Storage.getUrgencyScore(t) < 2);
        tasks = [...urgent, ...this.shuffleArray(nonUrgent)];

        this.matchingTasks = tasks;
        this.currentCardIndex = 0;

        if (tasks.length > 0) {
            this.showScreen('swipe');
            this.renderCards();
        } else {
            // No tasks at all - shouldn't happen with fallbacks
            this.showScreen('home');
        }
    },

    // Render swipe cards
    renderCards() {
        // Clean up any existing swipe listeners before rendering new cards
        this.cleanupSwipe();

        const stack = document.getElementById('card-stack');
        const noTasks = document.getElementById('no-tasks-message');

        // Get remaining tasks
        const remaining = this.matchingTasks.slice(this.currentCardIndex);

        if (remaining.length === 0) {
            stack.classList.add('hidden');
            noTasks.classList.remove('hidden');
            return;
        }

        stack.classList.remove('hidden');
        noTasks.classList.add('hidden');

        // Show only top 2 cards for performance
        const cardsToShow = remaining.slice(0, 2).reverse();

        stack.innerHTML = cardsToShow.map((task, i) => {
            let dueBadge = '';
            if (!task.isFallback && task.dueDate) {
                const daysUntil = Storage.getDaysUntilDue(task);
                if (daysUntil !== null) {
                    if (daysUntil < 0) {
                        dueBadge = '<span class="card-overdue">Overdue</span>';
                    } else if (daysUntil <= 3) {
                        dueBadge = '<span class="card-due-soon">Due soon</span>';
                    }
                }
            }

            return `
                <div class="swipe-card" data-index="${this.currentCardIndex + cardsToShow.length - 1 - i}" style="z-index: ${i + 1}">
                    <span class="card-type">${this.escapeHtml(task.type)}${task.isFallback ? ' (Suggestion)' : ''}${dueBadge}</span>
                    <h3 class="card-title">${this.escapeHtml(task.name)}</h3>
                    <p class="card-desc">${this.escapeHtml(task.desc || 'No description')}</p>
                    <div class="card-meta">
                        <span class="card-meta-item">⏱ ${task.time} min</span>
                        <span class="card-meta-item">⚡ ${task.energy}</span>
                        <span class="card-meta-item">👥 ${task.social}</span>
                    </div>
                </div>
            `;
        }).join('');

        // Initialize swipe on top card
        const topCard = stack.querySelector('.swipe-card:last-child');
        if (topCard) {
            this.initSwipe(topCard);
        }
    },

    // Initialize swipe gestures on a card
    initSwipe(card) {
        let startX = 0;
        let startY = 0;
        let currentX = 0;
        let isDragging = false;

        const onStart = (e) => {
            isDragging = true;
            startX = e.type === 'mousedown' ? e.clientX : e.touches[0].clientX;
            startY = e.type === 'mousedown' ? e.clientY : e.touches[0].clientY;
            card.classList.add('dragging');
        };

        const onMove = (e) => {
            if (!isDragging) return;

            const clientX = e.type === 'mousemove' ? e.clientX : e.touches[0].clientX;
            const clientY = e.type === 'mousemove' ? e.clientY : e.touches[0].clientY;
            currentX = clientX - startX;

            // Prevent page scroll when swiping horizontally
            if (Math.abs(currentX) > Math.abs(clientY - startY) && e.cancelable) {
                e.preventDefault();
            }

            // Apply transform
            const rotation = currentX * 0.1;
            card.style.transform = `translateX(${currentX}px) rotate(${rotation}deg)`;

            // Visual feedback
            card.classList.remove('swiping-left', 'swiping-right');
            if (currentX < -50) {
                card.classList.add('swiping-left');
            } else if (currentX > 50) {
                card.classList.add('swiping-right');
            }
        };

        const onEnd = () => {
            if (!isDragging) return;
            isDragging = false;
            card.classList.remove('dragging');

            const threshold = 100;

            if (currentX < -threshold) {
                // Swiped left - skip
                this.animateCardOut(card, 'left');
            } else if (currentX > threshold) {
                // Swiped right - accept
                this.animateCardOut(card, 'right');
            } else {
                // Return to center
                card.style.transform = '';
                card.classList.remove('swiping-left', 'swiping-right');
            }
        };

        // Mouse events
        card.addEventListener('mousedown', onStart);
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onEnd);

        // Touch events
        card.addEventListener('touchstart', onStart, { passive: true });
        card.addEventListener('touchmove', onMove, { passive: false });
        card.addEventListener('touchend', onEnd);

        // Store cleanup function to remove all swipe listeners
        this.swipeCleanup = () => {
            document.removeEventListener('mousemove', onMove);
            document.removeEventListener('mouseup', onEnd);
            card.removeEventListener('mousedown', onStart);
            card.removeEventListener('touchstart', onStart);
            card.removeEventListener('touchmove', onMove);
            card.removeEventListener('touchend', onEnd);
        };
    },

    // Animate card off screen
    animateCardOut(card, direction) {
        const task = this.matchingTasks[this.currentCardIndex];
        if (!task) return;
        const translateX = direction === 'left' ? -500 : 500;
        const rotation = direction === 'left' ? -30 : 30;

        card.style.transition = 'transform 0.3s ease';
        card.style.transform = `translateX(${translateX}px) rotate(${rotation}deg)`;

        setTimeout(() => {
            if (direction === 'right') {
                // Accepted
                this.acceptedTask = task;
                if (!task.isFallback) {
                    const acceptUpdates = { timesShown: (task.timesShown || 0) + 1 };
                    Storage.updateTask(task.id, acceptUpdates);
                    this.syncToCloud('update', task, acceptUpdates);
                }
                this.showAcceptedTask();
            } else {
                // Skipped
                if (!task.isFallback) {
                    const swipeSkipUpdates = {
                        timesShown: (task.timesShown || 0) + 1,
                        timesSkipped: (task.timesSkipped || 0) + 1
                    };
                    Storage.updateTask(task.id, swipeSkipUpdates);
                    this.syncToCloud('update', task, swipeSkipUpdates);
                }
                Storage.incrementSkipped();
                this.currentCardIndex++;
                this.renderCards();
            }
        }, 300);
    },

    // Show accepted task screen
    showAcceptedTask() {
        const container = document.getElementById('accepted-task');
        container.innerHTML = `
            <div class="task-name">${this.escapeHtml(this.acceptedTask.name)}</div>
            ${this.acceptedTask.desc ? `<div class="task-desc">${this.escapeHtml(this.acceptedTask.desc)}</div>` : ''}
        `;
        this.showScreen('accepted');
    },

    // Utility: Shuffle array
    shuffleArray(array) {
        const arr = [...array];
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    },

    // Utility: Escape HTML
    _escapeEl: null,
    escapeHtml(text) {
        if (!this._escapeEl) this._escapeEl = document.createElement('div');
        this._escapeEl.textContent = text;
        return this._escapeEl.innerHTML;
    },

    // Utility: Sanitize URL for use in HTML attributes
    sanitizeUrl(url) {
        if (!url) return '';
        try {
            const parsed = new URL(url);
            if (parsed.protocol === 'https:' || parsed.protocol === 'http:') {
                return this.escapeHtml(url);
            }
        } catch (e) { /* invalid URL */ }
        return '';
    },

    // Timer functions
    startTimer() {
        this.timerSeconds = 0;
        this.timerRunning = true;
        document.querySelector('.timer-task-name').textContent = this.acceptedTask.name;
        this.updateTimerDisplay();
        document.getElementById('btn-timer-pause').textContent = 'Pause';

        this.timerInterval = setInterval(() => {
            if (this.timerRunning) {
                this.timerSeconds++;
                this.updateTimerDisplay();
                // Persist elapsed time for page refresh recovery
                const timerState = sessionStorage.getItem('whatnow_timer');
                if (timerState) {
                    const state = JSON.parse(timerState);
                    state.seconds = this.timerSeconds;
                    sessionStorage.setItem('whatnow_timer', JSON.stringify(state));
                }
            }
        }, 1000);

        // Save timer state to sessionStorage
        sessionStorage.setItem('whatnow_timer', JSON.stringify({
            taskId: this.acceptedTask.id,
            startTime: Date.now()
        }));

        this.showScreen('timer');
    },

    updateTimerDisplay() {
        const minutes = Math.floor(this.timerSeconds / 60);
        const seconds = this.timerSeconds % 60;
        document.getElementById('timer-minutes').textContent = String(minutes).padStart(2, '0');
        document.getElementById('timer-seconds').textContent = String(seconds).padStart(2, '0');
    },

    toggleTimer() {
        this.timerRunning = !this.timerRunning;
        document.getElementById('btn-timer-pause').textContent = this.timerRunning ? 'Pause' : 'Resume';
    },

    cancelTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
        this.timerRunning = false;
        this.timerSeconds = 0;
        sessionStorage.removeItem('whatnow_timer');
    },

    // Complete task with celebration
    completeTask(fromTimer) {
        if (!this.acceptedTask || this._completing) return;
        this._completing = true;

        // Store previous rank for level-up check
        const stats = Storage.getStats();
        this.previousRank = Storage.getRank(stats.totalPoints);

        // Calculate and award points
        const points = Storage.calculatePoints(this.acceptedTask);
        this.lastPointsEarned = points;

        // Update task stats
        if (!this.acceptedTask.isFallback) {
            if (this.acceptedTask.recurring && this.acceptedTask.recurring !== 'none') {
                // Recurring tasks: advance due date and keep in list
                const updates = {
                    timesCompleted: (this.acceptedTask.timesCompleted || 0) + 1,
                    pointsEarned: (this.acceptedTask.pointsEarned || 0) + points,
                    dueDate: Storage.getNextDueDate(this.acceptedTask)
                };
                Storage.updateTask(this.acceptedTask.id, updates);
                this.syncToCloud('update', this.acceptedTask, updates);
            } else if (this.acceptedTask.dueDate) {
                // Non-recurring tasks with a due date: remove from task list
                Storage.deleteTask(this.acceptedTask.id);
                this.syncToCloud('delete', this.acceptedTask.id);
            } else {
                // Non-recurring tasks without a due date: keep in list (reusable)
                const updates = {
                    timesCompleted: (this.acceptedTask.timesCompleted || 0) + 1,
                    pointsEarned: (this.acceptedTask.pointsEarned || 0) + points
                };
                Storage.updateTask(this.acceptedTask.id, updates);
                this.syncToCloud('update', this.acceptedTask, updates);
            }
        }

        // Update global stats
        Storage.incrementCompleted();
        Storage.addPoints(points, this.acceptedTask.name);

        // Track time spent
        let minutesSpent = null;
        if (this.timerInterval) {
            if (this.timerSeconds > 0) {
                minutesSpent = Math.ceil(this.timerSeconds / 60);
            }
            this.cancelTimer();
        } else {
            // Use task's estimated time when timer wasn't used
            minutesSpent = this.acceptedTask.time;
        }
        if (minutesSpent) {
            Storage.addTimeSpent(minutesSpent);
        }

        // Log to completed history
        Storage.addCompletedTask(this.acceptedTask, points, minutesSpent);

        // Sync completed task and profile stats to cloud
        if (this.isLoggedIn && this.user) {
            (async () => {
                try {
                    await DB.logCompleted(this.user.id, this.acceptedTask.name, this.acceptedTask.type, points, minutesSpent);
                    const stats = Storage.getStats();
                    await DB.updateProfile(this.user.id, {
                        total_points: stats.totalPoints,
                        total_tasks_completed: stats.completed,
                        total_time_spent: stats.totalTimeSpent,
                        current_rank: Storage.getRank(stats.totalPoints).name
                    });
                } catch (e) { console.error('[Sync] complete', e); }
            })();
        }

        // Show celebration
        this._completing = false;
        this.showCelebration();
    },

    showCelebration() {
        const stats = Storage.getStats();
        const currentRank = Storage.getRank(stats.totalPoints);
        const leveledUp = currentRank.name !== this.previousRank.name;

        // Update celebration screen
        document.querySelector('.points-earned').textContent = `+${this.lastPointsEarned}`;

        // Pick a random motivational message
        const messages = [
            'Keep up the great work!',
            'You\'re crushing it!',
            'One step closer to your goals!',
            'That\'s how it\'s done!',
            'Productivity unlocked!',
            'Look at you go!',
            'Momentum is building!'
        ];
        document.querySelector('.celebration-message').textContent =
            messages[Math.floor(Math.random() * messages.length)];

        // Handle level up
        const rankUpSection = document.querySelector('.celebration-rank-up');
        if (leveledUp) {
            rankUpSection.classList.remove('hidden');
            rankUpSection.querySelector('.rank-up-title').textContent = currentRank.name;
        } else {
            rankUpSection.classList.add('hidden');
        }

        this.showScreen('celebration');
        this.startConfetti();
    },

    startConfetti() {
        // Cancel any previous confetti animation
        if (this._confettiId) {
            cancelAnimationFrame(this._confettiId);
            this._confettiId = null;
        }

        const canvas = document.getElementById('confetti-canvas');
        const ctx = canvas.getContext('2d');

        // Set canvas size
        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;

        const particles = [];
        const colors = ['#6366f1', '#f59e0b', '#10b981', '#ef4444', '#8b5cf6', '#ec4899'];

        // Reduce particles on smaller/lower-end devices
        const particleCount = canvas.width < 400 ? 50 : 80;

        // Create particles
        for (let i = 0; i < particleCount; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height - canvas.height,
                vx: (Math.random() - 0.5) * 4,
                vy: Math.random() * 3 + 2,
                color: colors[Math.floor(Math.random() * colors.length)],
                size: Math.random() * 8 + 4,
                rotation: Math.random() * 360,
                rotationSpeed: (Math.random() - 0.5) * 10
            });
        }

        let frameCount = 0;
        const maxFrames = 180; // 3 seconds at 60fps

        const animate = () => {
            if (frameCount >= maxFrames) {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                return;
            }

            ctx.clearRect(0, 0, canvas.width, canvas.height);

            particles.forEach(p => {
                ctx.save();
                ctx.translate(p.x, p.y);
                ctx.rotate(p.rotation * Math.PI / 180);
                ctx.fillStyle = p.color;
                ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size / 2);
                ctx.restore();

                p.x += p.vx;
                p.y += p.vy;
                p.vy += 0.1; // gravity
                p.rotation += p.rotationSpeed;
            });

            frameCount++;
            this._confettiId = requestAnimationFrame(animate);
        };

        this._confettiId = requestAnimationFrame(animate);
    },

    // Render gallery screen
    renderGallery() {
        const stats = Storage.getStats();
        const completed = Storage.getCompletedTasks();

        // Update stats display
        document.getElementById('gallery-total-tasks').textContent = stats.completed;
        document.getElementById('gallery-total-points').textContent = stats.totalPoints;

        const hours = Math.floor(stats.totalTimeSpent / 60);
        const mins = stats.totalTimeSpent % 60;
        document.getElementById('gallery-total-time').textContent =
            hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;

        // Show fun comparison
        const comparisonEl = document.getElementById('gallery-comparison');
        const timeComparison = Storage.getTimeComparison(stats.totalTimeSpent);
        const taskComparison = Storage.getTaskComparison(stats.completed);

        if (timeComparison || taskComparison) {
            comparisonEl.classList.remove('hidden');
            if (taskComparison) {
                comparisonEl.textContent = `${stats.completed} tasks = ${taskComparison.text}!`;
            } else if (timeComparison) {
                comparisonEl.textContent = `${hours}+ hours = ${timeComparison.text}!`;
            }
        } else {
            comparisonEl.classList.add('hidden');
        }

        // Render sticker bomb gallery
        const grid = document.getElementById('gallery-grid');
        const noCompleted = document.getElementById('no-completed');

        if (completed.length === 0) {
            grid.classList.add('hidden');
            noCompleted.classList.remove('hidden');
            return;
        }

        grid.classList.remove('hidden');
        noCompleted.classList.add('hidden');

        // Show most recent 50 completed tasks
        const recentCompleted = completed.slice(-50).reverse();

        grid.innerHTML = recentCompleted.map(task => `
            <div class="gallery-item" data-type="${this.escapeHtml(task.type)}">
                ${this.escapeHtml(task.name)}
                <span class="gallery-item-points">+${task.points} pts</span>
            </div>
        `).join('');
    },

    // Update rank display on home screen
    updateRankDisplay() {
        const stats = Storage.getStats();
        const rankDisplay = document.getElementById('rank-display');

        // Only show if user has any points
        if (stats.totalPoints > 0) {
            rankDisplay.classList.remove('hidden');
        } else {
            rankDisplay.classList.add('hidden');
            return;
        }

        const currentRank = Storage.getRank(stats.totalPoints);
        const nextRank = Storage.getNextRank(stats.totalPoints);

        // Update rank title
        rankDisplay.querySelector('.rank-title').textContent = currentRank.name;

        // Update points
        rankDisplay.querySelector('.points-value').textContent = stats.totalPoints;

        // Update progress bar
        if (nextRank) {
            const prevMinPoints = currentRank.minPoints;
            const progress = ((stats.totalPoints - prevMinPoints) / (nextRank.minPoints - prevMinPoints)) * 100;
            rankDisplay.querySelector('.rank-progress-fill').style.width = Math.min(progress, 100) + '%';
            rankDisplay.querySelector('.rank-next').textContent = `Next: ${nextRank.name}`;
            rankDisplay.querySelector('.rank-progress').classList.remove('hidden');
        } else {
            rankDisplay.querySelector('.rank-progress-fill').style.width = '100%';
            rankDisplay.querySelector('.rank-next').textContent = 'Max rank achieved!';
        }
    },

    // ==================== AUTH & SOCIAL FEATURES ====================

    // Bind auth events
    bindAuthEvents() {
        // Login screen - OAuth providers
        document.getElementById('btn-google-login').addEventListener('click', () => {
            Supabase.signInWithGoogle();
        });

        // Facebook button is disabled - no event listener needed

        // Login screen - Email
        document.getElementById('btn-email-login').addEventListener('click', () => {
            this.emailLogin();
        });

        document.getElementById('btn-email-signup').addEventListener('click', () => {
            this.emailSignup();
        });

        document.getElementById('btn-skip-login').addEventListener('click', () => {
            this.showScreen('home');
        });

        // Resend confirmation
        document.getElementById('btn-resend-confirmation').addEventListener('click', () => {
            this.resendConfirmation();
        });

        // Password visibility toggles
        this.bindPasswordToggle('btn-toggle-password', 'login-password');
        this.bindPasswordToggle('btn-toggle-reset-password', 'reset-new-password');

        // Forgot password
        document.getElementById('btn-forgot-password').addEventListener('click', () => {
            document.getElementById('forgot-email').value = document.getElementById('login-email').value || '';
            this.showScreen('forgot-password');
        });

        document.getElementById('btn-send-reset').addEventListener('click', () => {
            this.forgotPassword();
        });

        document.getElementById('btn-submit-new-password').addEventListener('click', () => {
            this.submitNewPassword();
        });

        // Help & FAQ
        document.getElementById('btn-view-help').addEventListener('click', () => {
            this.showScreen('help');
        });

        // FAQ accordion
        document.querySelectorAll('.faq-question').forEach(btn => {
            btn.addEventListener('click', () => {
                const answer = btn.nextElementSibling;
                const isOpen = !answer.classList.contains('hidden');
                // Close all
                document.querySelectorAll('.faq-answer').forEach(a => a.classList.add('hidden'));
                document.querySelectorAll('.faq-question').forEach(q => q.classList.remove('open'));
                if (!isOpen) {
                    answer.classList.remove('hidden');
                    btn.classList.add('open');
                }
            });
        });

        // Task filters
        document.getElementById('filter-time').addEventListener('change', () => this.renderTaskList());
        document.getElementById('filter-energy').addEventListener('change', () => this.renderTaskList());
        document.getElementById('filter-social').addEventListener('change', () => this.renderTaskList());

        // Profile screen
        document.getElementById('btn-edit-profile').addEventListener('click', () => {
            this.openEditProfile();
        });

        document.getElementById('btn-cancel-edit-profile').addEventListener('click', () => {
            document.getElementById('modal-edit-profile').classList.add('hidden');
        });

        document.getElementById('btn-save-profile').addEventListener('click', () => {
            this.saveProfile();
        });

        document.getElementById('btn-view-groups').addEventListener('click', () => {
            this.renderGroups();
            this.showScreen('groups');
        });

        document.getElementById('btn-logout').addEventListener('click', () => {
            this.logout();
        });

        document.getElementById('btn-login-from-profile').addEventListener('click', () => {
            this.showScreen('login');
        });

        document.getElementById('btn-view-tutorial').addEventListener('click', () => {
            this.openTutorialFromProfile();
        });

        // Groups screen
        document.getElementById('btn-create-group').addEventListener('click', () => {
            document.getElementById('modal-create-group').classList.remove('hidden');
            document.getElementById('group-name').focus();
        });

        document.getElementById('btn-cancel-create-group').addEventListener('click', () => {
            document.getElementById('modal-create-group').classList.add('hidden');
        });

        document.getElementById('btn-confirm-create-group').addEventListener('click', () => {
            this.createGroup();
        });

        document.getElementById('btn-join-group').addEventListener('click', () => {
            document.getElementById('modal-join-group').classList.remove('hidden');
            document.getElementById('join-code').focus();
        });

        document.getElementById('btn-cancel-join-group').addEventListener('click', () => {
            document.getElementById('modal-join-group').classList.add('hidden');
        });

        document.getElementById('btn-confirm-join-group').addEventListener('click', () => {
            this.joinGroup();
        });

        // Leaderboard screen
        document.getElementById('btn-copy-code').addEventListener('click', () => {
            this.copyInviteCode();
        });

        document.getElementById('btn-share-code').addEventListener('click', () => {
            this.shareInviteCode();
        });

        document.getElementById('btn-leave-group').addEventListener('click', () => {
            this.leaveGroup();
        });

        // Edit group
        document.getElementById('btn-edit-group').addEventListener('click', () => {
            this.openEditGroupModal();
        });

        document.getElementById('btn-cancel-edit-group').addEventListener('click', () => {
            document.getElementById('modal-edit-group').classList.add('hidden');
        });

        document.getElementById('btn-save-edit-group').addEventListener('click', () => {
            this.saveGroupEdit();
        });

        // Challenges
        document.getElementById('btn-create-challenge').addEventListener('click', () => {
            this.openCreateChallengeModal();
        });

        document.getElementById('btn-cancel-challenge').addEventListener('click', () => {
            document.getElementById('modal-create-challenge').classList.add('hidden');
        });

        document.getElementById('btn-save-challenge').addEventListener('click', () => {
            this.saveChallenge();
        });
    },

    // Update UI based on auth state
    updateAuthUI() {
        const logoutBtn = document.getElementById('btn-logout');
        const loginBtn = document.getElementById('btn-login-from-profile');
        const editProfileBtn = document.getElementById('btn-edit-profile');

        if (this.isLoggedIn) {
            logoutBtn.classList.remove('hidden');
            loginBtn.classList.add('hidden');
            editProfileBtn.classList.remove('hidden');
        } else {
            logoutBtn.classList.add('hidden');
            loginBtn.classList.remove('hidden');
            editProfileBtn.classList.add('hidden');
        }
    },

    // Load user profile from Supabase
    async loadProfile() {
        if (!Supabase.user) {
            await Supabase.getUser();
        }

        if (Supabase.user) {
            this.user = Supabase.user;
            const { data, error } = await DB.getProfile(this.user.id);

            if (error) {
                // Don't try to create a profile if the GET itself failed
                console.error('Error loading profile:', error.message);
                return;
            }

            if (data && data[0]) {
                this.profile = data[0];
            } else {
                // Profile not found — trigger may still be creating it, wait briefly and retry
                await new Promise(r => setTimeout(r, 1000));
                const { data: retryData } = await DB.getProfile(this.user.id);

                if (retryData && retryData[0]) {
                    this.profile = retryData[0];
                } else {
                    // Profile genuinely doesn't exist, create one using metadata
                    const displayName = this.user.user_metadata?.full_name ||
                                       this.user.user_metadata?.name ||
                                       this.user.email?.split('@')[0] || 'User';
                    const avatarUrl = this.user.user_metadata?.avatar_url ||
                                     this.user.user_metadata?.picture || null;

                    await DB.createProfile(this.user.id, this.user.email, displayName, avatarUrl);
                    const { data: newData } = await DB.getProfile(this.user.id);
                    if (newData && newData[0]) {
                        this.profile = newData[0];
                    }
                }
            }

            // Auto-sync data to cloud after login
            await this.autoSyncToCloud();
        }
    },

    // Render profile screen
    renderProfile() {
        const stats = Storage.getStats();

        if (this.isLoggedIn && this.user) {
            // Use profile display_name, then Google full_name, then email prefix
            const displayName = this.profile?.display_name ||
                               this.user.user_metadata?.full_name ||
                               this.user.user_metadata?.name ||
                               this.user.email?.split('@')[0] || 'User';
            document.getElementById('profile-name').textContent = displayName;
            document.getElementById('profile-email').textContent = this.user.email || '';

            const avatarEl = document.getElementById('profile-avatar');
            const avatarUrl = this.user.user_metadata?.avatar_url || this.user.user_metadata?.picture;
            const safeAvatarUrl = this.sanitizeUrl(avatarUrl);
            if (safeAvatarUrl) {
                avatarEl.innerHTML = `<img src="${safeAvatarUrl}" alt="Avatar">`;
            } else {
                avatarEl.innerHTML = '<span class="avatar-placeholder">' +
                    (displayName[0] || '?').toUpperCase() + '</span>';
            }
        } else {
            document.getElementById('profile-name').textContent = 'Guest';
            document.getElementById('profile-email').textContent = 'Not signed in';
            document.getElementById('profile-avatar').innerHTML = '<span class="avatar-placeholder">?</span>';
        }

        document.getElementById('profile-points').textContent = stats.totalPoints;
        document.getElementById('profile-tasks').textContent = stats.completed;
        document.getElementById('profile-rank').textContent = Storage.getRank(stats.totalPoints).name.replace('Task ', '');

        // Show/hide notifications button
        const notifBtn = document.getElementById('btn-enable-notifications-profile');
        if (typeof NotificationManager !== 'undefined' &&
            NotificationManager.isSupported() &&
            NotificationManager.getPermission() !== 'granted') {
            notifBtn.classList.remove('hidden');
        } else {
            notifBtn.classList.add('hidden');
        }

        this.updateAuthUI();
    },

    // Check and execute pending action after login
    async checkPendingAction() {
        // Try to restore from sessionStorage first
        if (!this.pendingAction) {
            const stored = sessionStorage.getItem('whatnow_pending_action');
            if (stored) {
                this.pendingAction = JSON.parse(stored);
            }
        }

        if (!this.pendingAction || !this.isLoggedIn) return false;

        const action = this.pendingAction;
        this.pendingAction = null;
        sessionStorage.removeItem('whatnow_pending_action');

        try {
            if (action.type === 'createGroup') {
                const { data, error } = await DB.createGroup(this.user.id, action.data.name, action.data.desc);
                if (error) throw error;
                await this.renderGroups();
                this.showScreen('groups');
                return true;
            } else if (action.type === 'joinGroup') {
                const { data, error } = await DB.joinGroup(this.user.id, action.data.code);
                if (error) throw error;
                await this.renderGroups();
                this.showScreen('groups');
                return true;
            }
        } catch (e) {
            alert('Failed to complete action: ' + e.message);
        }
        return false;
    },

    // Email login
    async emailLogin() {
        // If in signup mode, toggle back to login mode
        if (this.isSignupMode) {
            this.toggleSignupMode(false);
            return;
        }

        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;
        const errorEl = document.getElementById('login-error');

        if (!email || !password) {
            errorEl.textContent = 'Please enter email and password';
            errorEl.classList.remove('hidden');
            return;
        }

        if (!email.includes('@') || !email.includes('.')) {
            errorEl.textContent = 'Please enter a valid email address';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            errorEl.classList.add('hidden');
            await Supabase.signIn(email, password);
            this.isLoggedIn = true;
            await this.loadProfile();
            this.updateAuthUI();

            // Check for pending action before navigating
            const hadPendingAction = await this.checkPendingAction();
            if (!hadPendingAction) {
                this.showScreen('home');
            }
        } catch (e) {
            const msg = e.message || 'Login failed';
            errorEl.style.color = '';
            if (msg.includes('confirm your email')) {
                errorEl.textContent = 'Email not confirmed. Check your inbox or resend the link.';
                document.getElementById('btn-resend-confirmation').classList.remove('hidden');
                this._resendEmail = email;
            } else {
                errorEl.textContent = msg;
                document.getElementById('btn-resend-confirmation').classList.add('hidden');
            }
            errorEl.classList.remove('hidden');
        }
    },

    // Resend confirmation email
    async resendConfirmation() {
        const email = this._resendEmail;
        if (!email) return;
        const errorEl = document.getElementById('login-error');
        try {
            await Supabase.resendConfirmation(email);
            errorEl.textContent = 'Confirmation email sent! Check your inbox.';
            errorEl.style.color = '#4ade80';
            errorEl.classList.remove('hidden');
            document.getElementById('btn-resend-confirmation').classList.add('hidden');
        } catch (e) {
            errorEl.textContent = e.message || 'Failed to resend. Try again later.';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
        }
    },

    // Password visibility toggle helper
    bindPasswordToggle(btnId, inputId) {
        const btn = document.getElementById(btnId);
        if (!btn) return;
        btn.addEventListener('click', () => {
            const input = document.getElementById(inputId);
            const isPassword = input.type === 'password';
            input.type = isPassword ? 'text' : 'password';
            btn.querySelector('.eye-icon').classList.toggle('hidden', !isPassword);
            btn.querySelector('.eye-off-icon').classList.toggle('hidden', isPassword);
        });
    },

    // Forgot password - send reset link
    async forgotPassword() {
        const email = document.getElementById('forgot-email').value.trim();
        const errorEl = document.getElementById('forgot-error');

        if (!email || !email.includes('@') || !email.includes('.')) {
            errorEl.textContent = 'Please enter a valid email address';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            await Supabase.resetPasswordForEmail(email);
            errorEl.textContent = 'Reset link sent! Check your email inbox.';
            errorEl.style.color = '#4ade80';
            errorEl.classList.remove('hidden');
        } catch (e) {
            errorEl.textContent = e.message || 'Failed to send reset link';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
        }
    },

    // Submit new password after reset
    async submitNewPassword() {
        const password = document.getElementById('reset-new-password').value;
        const confirm = document.getElementById('reset-confirm-password').value;
        const errorEl = document.getElementById('reset-error');

        if (!password || password.length < 6) {
            errorEl.textContent = 'Password must be at least 6 characters';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
            return;
        }

        if (password !== confirm) {
            errorEl.textContent = 'Passwords do not match';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            await Supabase.updateUser({ password });
            errorEl.textContent = 'Password updated! You can now sign in.';
            errorEl.style.color = '#4ade80';
            errorEl.classList.remove('hidden');
            setTimeout(() => this.showScreen('login'), 2000);
        } catch (e) {
            errorEl.textContent = e.message || 'Failed to update password';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
        }
    },

    // Show mini tutorial overlay
    showMiniTutorial(key, title, message) {
        if (localStorage.getItem('whatnow_minitutorial_' + key)) return;
        localStorage.setItem('whatnow_minitutorial_' + key, 'true');

        const overlay = document.createElement('div');
        overlay.className = 'mini-tutorial-overlay';
        overlay.innerHTML = `
            <div class="mini-tutorial-card">
                <h3>${this.escapeHtml(title)}</h3>
                <p>${message}</p>
                <button class="btn btn-primary" style="padding: 10px 24px;">Got it!</button>
            </div>
        `;
        overlay.querySelector('.btn').addEventListener('click', () => overlay.remove());
        overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
        document.body.appendChild(overlay);
    },

    // Toggle signup mode (show/hide name field)
    isSignupMode: false,

    toggleSignupMode(showSignup) {
        this.isSignupMode = showSignup;
        const nameField = document.getElementById('name-field');
        const loginBtn = document.getElementById('btn-email-login');
        const signupBtn = document.getElementById('btn-email-signup');

        if (showSignup) {
            nameField.classList.remove('hidden');
            loginBtn.textContent = 'Back to Sign In';
            signupBtn.textContent = 'Create Account';
            signupBtn.classList.add('btn-primary');
            signupBtn.classList.remove('btn-outline');
            loginBtn.classList.remove('btn-primary');
            loginBtn.classList.add('btn-outline');
        } else {
            nameField.classList.add('hidden');
            loginBtn.textContent = 'Sign In';
            signupBtn.textContent = 'Create Account';
            loginBtn.classList.add('btn-primary');
            loginBtn.classList.remove('btn-outline');
            signupBtn.classList.remove('btn-primary');
            signupBtn.classList.add('btn-outline');
        }
    },

    // Email signup
    async emailSignup() {
        // If not in signup mode, toggle to signup mode
        if (!this.isSignupMode) {
            this.toggleSignupMode(true);
            document.getElementById('login-name').focus();
            return;
        }

        const name = document.getElementById('login-name').value.trim();
        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;
        const errorEl = document.getElementById('login-error');

        if (!email || !password) {
            errorEl.textContent = 'Please enter email and password';
            errorEl.classList.remove('hidden');
            return;
        }

        if (!email.includes('@') || !email.includes('.')) {
            errorEl.textContent = 'Please enter a valid email address';
            errorEl.classList.remove('hidden');
            return;
        }

        if (password.length < 6) {
            errorEl.textContent = 'Password must be at least 6 characters';
            errorEl.classList.remove('hidden');
            return;
        }

        try {
            errorEl.classList.add('hidden');
            const data = await Supabase.signUp(email, password, name || null);

            // Check if email confirmation is required
            if (data.id && !data.access_token) {
                errorEl.textContent = 'Please check your email to confirm your account';
                errorEl.style.color = '#4ade80';
                errorEl.classList.remove('hidden');
                this.toggleSignupMode(false);
                return;
            }

            this.isLoggedIn = true;
            await this.loadProfile();
            this.updateAuthUI();

            // Check for pending action before navigating
            const hadPendingAction = await this.checkPendingAction();
            if (!hadPendingAction) {
                this.showScreen('home');
            }
        } catch (e) {
            errorEl.textContent = e.message || 'Signup failed';
            errorEl.style.color = '';
            errorEl.classList.remove('hidden');
        }
    },

    // Logout
    async logout() {
        await Supabase.signOut();
        this.isLoggedIn = false;
        this.user = null;
        this.profile = null;
        this.updateAuthUI();
        this.renderProfile();
    },

    // Open edit profile modal
    openEditProfile() {
        const currentName = this.profile?.display_name ||
                           this.user?.user_metadata?.full_name ||
                           this.user?.email?.split('@')[0] || '';
        document.getElementById('edit-display-name').value = currentName;
        document.getElementById('modal-edit-profile').classList.remove('hidden');
        document.getElementById('edit-display-name').focus();
    },

    // Save profile changes
    async saveProfile() {
        const newName = document.getElementById('edit-display-name').value.trim();

        if (!newName) {
            alert('Please enter a display name');
            return;
        }

        try {
            await DB.updateProfile(this.user.id, { display_name: newName });

            // Update local profile
            if (this.profile) {
                this.profile.display_name = newName;
            } else {
                this.profile = { display_name: newName };
            }

            document.getElementById('modal-edit-profile').classList.add('hidden');
            this.renderProfile();
        } catch (e) {
            console.error('Error saving profile:', e);
            alert('Failed to save profile: ' + e.message);
        }
    },

    // Sync a single mutation to cloud (fire-and-forget)
    syncToCloud(action, task, updates) {
        if (!this.isLoggedIn || !this.user) return;
        (async () => {
            try {
                if (action === 'add') await DB.cloudAddTask(this.user.id, task);
                else if (action === 'update') await DB.cloudUpdateTask(this.user.id, task.id, updates);
                else if (action === 'delete') await DB.cloudDeleteTask(this.user.id, task);
            } catch (e) { console.error('[Sync]', action, e); }
        })();
    },

    // Auto-sync local data to cloud (called after login, no alerts)
    async autoSyncToCloud() {
        if (!this.isLoggedIn || !this.user || this._syncing) {
            return;
        }
        this._syncing = true;

        try {
            // Sync tasks
            const tasks = Storage.getTasks();
            if (tasks.length > 0) {
                await DB.syncTasks(this.user.id, tasks);
            }

            // Update profile with stats
            const stats = Storage.getStats();
            await DB.updateProfile(this.user.id, {
                total_points: stats.totalPoints,
                total_tasks_completed: stats.completed,
                total_time_spent: stats.totalTimeSpent,
                current_rank: Storage.getRank(stats.totalPoints).name
            });

            // Sync only new completed tasks (not yet synced)
            const completed = Storage.getCompletedTasks();
            const lastSyncedId = localStorage.getItem('whatnow_last_synced_completed') || '';
            const lastSyncedIndex = lastSyncedId
                ? completed.findIndex(t => t.id === lastSyncedId)
                : -1;
            const unsynced = completed.slice(lastSyncedIndex + 1);

            for (const task of unsynced) {
                await DB.logCompleted(
                    this.user.id,
                    task.name,
                    task.type,
                    task.points,
                    task.timeSpent
                );
            }

            if (completed.length > 0) {
                localStorage.setItem('whatnow_last_synced_completed', completed[completed.length - 1].id);
            }

            console.log('[Sync] Data synced to cloud');
        } catch (e) {
            console.error('[Sync] Auto-sync error:', e);
        } finally {
            this._syncing = false;
        }
    },

    // Render groups screen
    async renderGroups() {
        const container = document.getElementById('groups-list');
        const noGroups = document.getElementById('no-groups');

        if (!this.isLoggedIn) {
            container.classList.add('hidden');
            noGroups.classList.remove('hidden');
            noGroups.innerHTML = '<p>Sign in to create or join groups</p>';
            return;
        }

        const { data: groups, error } = await DB.getMyGroups(this.user.id);

        if (error || !groups || groups.length === 0) {
            container.classList.add('hidden');
            noGroups.classList.remove('hidden');
            noGroups.innerHTML = `
                <p>No groups yet!</p>
                <p class="groups-hint">Create or join a group to compete on leaderboards.</p>
            `;
            return;
        }

        container.classList.remove('hidden');
        noGroups.classList.add('hidden');

        // Store groups for later reference
        this._groupsCache = {};
        groups.forEach(g => this._groupsCache[g.id] = g);

        container.innerHTML = groups.map(group => `
            <div class="group-item" data-id="${group.id}">
                <div class="group-item-name">${this.escapeHtml(group.name)}</div>
                <div class="group-item-meta">${this.escapeHtml(group.description || 'No description')}</div>
            </div>
        `).join('');

        // Bind click events
        container.querySelectorAll('.group-item').forEach(item => {
            item.addEventListener('click', () => {
                const group = this._groupsCache[item.dataset.id];
                if (group) this.openLeaderboard(group);
            });
        });
    },

    // Create group
    async createGroup() {
        const name = document.getElementById('group-name').value.trim();
        const desc = document.getElementById('group-desc').value.trim();

        if (!name) return;

        if (!this.isLoggedIn) {
            // Save pending action to resume after login
            this.pendingAction = { type: 'createGroup', data: { name, desc } };
            sessionStorage.setItem('whatnow_pending_action', JSON.stringify(this.pendingAction));

            document.getElementById('modal-create-group').classList.add('hidden');
            this.showScreen('login');
            return;
        }

        const btn = document.getElementById('btn-confirm-create-group');
        btn.disabled = true;
        btn.textContent = 'Creating...';

        try {
            const { data, error } = await DB.createGroup(this.user.id, name, desc);
            if (error) throw error;

            document.getElementById('group-name').value = '';
            document.getElementById('group-desc').value = '';
            document.getElementById('modal-create-group').classList.add('hidden');

            // Open the newly created group's leaderboard so user can see invite code
            if (data && data.id) {
                await this.openLeaderboard(data);
            } else {
                await this.renderGroups();
                this.showScreen('groups');
            }
        } catch (e) {
            alert('Failed to create group: ' + (e.message || 'Unknown error'));
        } finally {
            btn.disabled = false;
            btn.textContent = 'Create';
        }
    },

    // Join group
    async joinGroup() {
        const code = document.getElementById('join-code').value.trim().toUpperCase();

        if (!code || code.length !== 6) {
            alert('Please enter a valid 6-character invite code');
            return;
        }

        if (!this.isLoggedIn) {
            // Save pending action to resume after login
            this.pendingAction = { type: 'joinGroup', data: { code } };
            sessionStorage.setItem('whatnow_pending_action', JSON.stringify(this.pendingAction));

            document.getElementById('modal-join-group').classList.add('hidden');
            this.showScreen('login');
            return;
        }

        try {
            const { data, error } = await DB.joinGroup(this.user.id, code);
            if (error) throw error;

            document.getElementById('join-code').value = '';
            document.getElementById('modal-join-group').classList.add('hidden');

            await this.renderGroups();
            this.showScreen('groups');
        } catch (e) {
            alert('Failed to join group: ' + e.message);
        }
    },

    // Open leaderboard for a group
    async openLeaderboard(group) {
        // Accept full group object or legacy (groupId, inviteCode) args
        if (typeof group === 'string') {
            group = { id: group, invite_code: arguments[1] };
        }

        // Ensure we have full group data (including created_by)
        if (!group.created_by) {
            try {
                const query = new SupabaseQuery(Supabase, 'groups');
                const { data } = await query.eq('id', group.id).execute();
                if (data?.[0]) {
                    group = { ...group, ...data[0] };
                }
            } catch (e) { /* continue with partial data */ }
        }

        this.currentGroup = group;

        document.getElementById('group-invite-code').textContent = group.invite_code;
        document.getElementById('leaderboard-title').textContent = this.escapeHtml(group.name || 'Leaderboard');

        // Show/hide edit button for group creator
        const editBtn = document.getElementById('btn-edit-group');
        if (group.created_by === this.user?.id) {
            editBtn.classList.remove('hidden');
        } else {
            editBtn.classList.add('hidden');
        }

        // Show share button if Web Share API is available
        const shareBtn = document.getElementById('btn-share-code');
        if (navigator.share) {
            shareBtn.classList.remove('hidden');
        } else {
            shareBtn.classList.add('hidden');
        }

        const container = document.getElementById('leaderboard-list');
        const emptyEl = document.getElementById('leaderboard-empty');

        container.innerHTML = '<div class="loading">Loading...</div>';
        this.showScreen('leaderboard');

        try {
            const { data: leaderboard, error } = await DB.getLeaderboard(group.id);

            if (error || !leaderboard || leaderboard.length === 0) {
                container.classList.add('hidden');
                emptyEl.classList.remove('hidden');
            } else {
                container.classList.remove('hidden');
                emptyEl.classList.add('hidden');

                container.innerHTML = leaderboard.map((entry, index) => {
                    const isMe = entry.user_id === this.user?.id;
                    const initial = (entry.display_name?.[0] || '?').toUpperCase();

                    return `
                        <div class="leaderboard-item${isMe ? ' is-me' : ''}">
                            <div class="leaderboard-position">${index + 1}</div>
                            <div class="leaderboard-avatar">
                                ${this.sanitizeUrl(entry.avatar_url)
                                    ? `<img src="${this.sanitizeUrl(entry.avatar_url)}" alt="">`
                                    : `<span>${initial}</span>`}
                            </div>
                            <div class="leaderboard-info">
                                <div class="leaderboard-name">${this.escapeHtml(entry.display_name || 'User')}</div>
                                <div class="leaderboard-rank">${entry.current_rank || 'Task Newbie'}</div>
                            </div>
                            <div class="leaderboard-stats">
                                <div class="leaderboard-points">${entry.weekly_points} pts</div>
                                <div class="leaderboard-tasks">${entry.weekly_tasks} tasks</div>
                            </div>
                        </div>
                    `;
                }).join('');
            }
        } catch (e) {
            container.innerHTML = '<div class="error">Failed to load leaderboard</div>';
        }

        // Load additional sections in parallel
        this.renderActivityFeed(group.id);
        this.renderMemberList(group.id);
        this.renderChallenge(group.id);
    },

    // Copy invite code
    copyInviteCode() {
        const code = document.getElementById('group-invite-code').textContent;
        navigator.clipboard.writeText(code).then(() => {
            const btn = document.getElementById('btn-copy-code');
            btn.textContent = 'Copied!';
            setTimeout(() => btn.textContent = 'Copy', 2000);
        });
    },

    // Share invite code via Web Share API
    shareInviteCode() {
        const group = this.currentGroup;
        if (!group) return;

        const text = `Join my group "${group.name || 'my group'}" on What Now! Use invite code: ${group.invite_code}`;

        if (navigator.share) {
            navigator.share({ title: 'Join my What Now group', text }).catch(() => {});
        } else {
            // Fallback to copy
            navigator.clipboard.writeText(text).then(() => {
                const btn = document.getElementById('btn-share-code');
                btn.textContent = 'Copied!';
                setTimeout(() => btn.textContent = 'Share', 2000);
            });
        }
    },

    // Open edit group modal
    openEditGroupModal() {
        const group = this.currentGroup;
        if (!group) return;

        document.getElementById('edit-group-name').value = group.name || '';
        document.getElementById('edit-group-desc').value = group.description || '';
        document.getElementById('modal-edit-group').classList.remove('hidden');
        document.getElementById('edit-group-name').focus();
    },

    // Save group edits
    async saveGroupEdit() {
        const group = this.currentGroup;
        if (!group) return;

        const name = document.getElementById('edit-group-name').value.trim();
        const description = document.getElementById('edit-group-desc').value.trim();

        if (!name) return;

        const btn = document.getElementById('btn-save-edit-group');
        btn.disabled = true;
        btn.textContent = 'Saving...';

        try {
            const { error } = await DB.updateGroup(group.id, { name, description });
            if (error) throw error;

            // Update cached group
            this.currentGroup.name = name;
            this.currentGroup.description = description;
            document.getElementById('leaderboard-title').textContent = this.escapeHtml(name);

            document.getElementById('modal-edit-group').classList.add('hidden');
        } catch (e) {
            alert('Failed to update group: ' + (e.message || 'Unknown error'));
        } finally {
            btn.disabled = false;
            btn.textContent = 'Save';
        }
    },

    // Render activity feed
    async renderActivityFeed(groupId) {
        const listEl = document.getElementById('activity-list');
        const emptyEl = document.getElementById('activity-empty');

        listEl.innerHTML = '';
        emptyEl.classList.add('hidden');

        const { data: activities } = await DB.getGroupActivity(groupId);

        if (!activities || activities.length === 0) {
            emptyEl.classList.remove('hidden');
            return;
        }

        listEl.innerHTML = activities.map(a => {
            const timeAgo = this.formatTimeAgo(a.completed_at);
            return `
                <div class="activity-item">
                    <div class="activity-text">
                        <strong>${this.escapeHtml(a.display_name)}</strong> completed
                        <em>${this.escapeHtml(a.task_name)}</em>
                        — <span class="activity-points">+${a.points} pts</span>
                    </div>
                    <div class="activity-time">${timeAgo}</div>
                </div>
            `;
        }).join('');
    },

    // Format relative time
    formatTimeAgo(dateStr) {
        const now = new Date();
        const date = new Date(dateStr);
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);

        if (diffMins < 1) return 'just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `${diffHours}h ago`;
        const diffDays = Math.floor(diffHours / 24);
        return `${diffDays}d ago`;
    },

    // Render member list
    async renderMemberList(groupId) {
        const listEl = document.getElementById('member-list');
        const countEl = document.getElementById('member-count');

        listEl.innerHTML = '';

        const { data: members } = await DB.getGroupMembers(groupId);

        if (!members || members.length === 0) {
            countEl.textContent = '0';
            return;
        }

        countEl.textContent = members.length;
        const isCreator = this.currentGroup?.created_by === this.user?.id;

        listEl.innerHTML = members.map(m => {
            const profile = m.profiles || {};
            const initial = (profile.display_name?.[0] || '?').toUpperCase();
            const isSelf = m.user_id === this.user?.id;
            const showRemove = isCreator && !isSelf;

            return `
                <div class="member-item">
                    <div class="member-avatar">
                        ${this.sanitizeUrl(profile.avatar_url)
                            ? `<img src="${this.sanitizeUrl(profile.avatar_url)}" alt="">`
                            : `<span>${initial}</span>`}
                    </div>
                    <div class="member-info">
                        <div class="member-name">${this.escapeHtml(profile.display_name || 'User')}${isSelf ? ' (you)' : ''}</div>
                        <div class="member-rank">${profile.current_rank || 'Task Newbie'}</div>
                    </div>
                    ${showRemove ? `<button class="btn btn-small btn-danger-text btn-remove-member" data-user-id="${m.user_id}">Remove</button>` : ''}
                </div>
            `;
        }).join('');

        // Bind remove buttons
        listEl.querySelectorAll('.btn-remove-member').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.removeMember(groupId, btn.dataset.userId);
            });
        });
    },

    // Remove a member from the group
    async removeMember(groupId, userId) {
        if (!confirm('Remove this member from the group?')) return;

        try {
            const { error } = await DB.removeMember(groupId, userId);
            if (error) throw error;
            await this.renderMemberList(groupId);
        } catch (e) {
            alert('Failed to remove member: ' + (e.message || 'Unknown error'));
        }
    },

    // Render challenge section
    async renderChallenge(groupId) {
        const section = document.getElementById('challenge-section');
        const activeEl = document.getElementById('active-challenge');
        const createBtn = document.getElementById('btn-create-challenge');
        const isCreator = this.currentGroup?.created_by === this.user?.id;

        section.classList.remove('hidden');

        const { data: challenge } = await DB.getActiveChallenge(groupId);

        if (!challenge) {
            activeEl.innerHTML = '';
            if (isCreator) {
                createBtn.classList.remove('hidden');
            } else {
                createBtn.classList.add('hidden');
                section.classList.add('hidden');
            }
            return;
        }

        createBtn.classList.add('hidden');

        // Get progress
        const { data: completed } = await DB.getChallengeProgress(groupId, challenge.start_date);
        const progress = Math.min(completed, challenge.target_tasks);
        const pct = Math.round((progress / challenge.target_tasks) * 100);

        const endDate = new Date(challenge.end_date);
        const daysLeft = Math.max(0, Math.ceil((endDate - new Date()) / (1000 * 60 * 60 * 24)));

        activeEl.innerHTML = `
            <div class="challenge-card">
                <div class="challenge-header">
                    <div class="challenge-name">${this.escapeHtml(challenge.title)}</div>
                    <div class="challenge-meta">${daysLeft} day${daysLeft !== 1 ? 's' : ''} left &middot; +${challenge.bonus_points} bonus pts</div>
                </div>
                <div class="challenge-progress-bar">
                    <div class="challenge-progress-fill" style="width: ${pct}%"></div>
                </div>
                <div class="challenge-progress-text">${progress} / ${challenge.target_tasks} tasks (${pct}%)</div>
            </div>
        `;
    },

    // Open create challenge modal
    openCreateChallengeModal() {
        document.getElementById('challenge-title').value = '';
        document.getElementById('challenge-target').value = '50';
        document.getElementById('challenge-bonus').value = '100';
        document.getElementById('challenge-duration').value = '7';
        document.getElementById('modal-create-challenge').classList.remove('hidden');
        document.getElementById('challenge-title').focus();
    },

    // Save new challenge
    async saveChallenge() {
        const title = document.getElementById('challenge-title').value.trim();
        const targetTasks = parseInt(document.getElementById('challenge-target').value) || 50;
        const bonusPoints = parseInt(document.getElementById('challenge-bonus').value) || 100;
        const duration = parseInt(document.getElementById('challenge-duration').value) || 7;

        if (!title) return;
        if (!this.currentGroup || !this.isLoggedIn) return;

        const btn = document.getElementById('btn-save-challenge');
        btn.disabled = true;
        btn.textContent = 'Creating...';

        try {
            const { error } = await DB.createChallenge(this.currentGroup.id, this.user.id, {
                title, targetTasks, bonusPoints, duration
            });
            if (error) throw error;

            document.getElementById('modal-create-challenge').classList.add('hidden');
            await this.renderChallenge(this.currentGroup.id);
        } catch (e) {
            alert('Failed to create challenge: ' + (e.message || 'Unknown error'));
        } finally {
            btn.disabled = false;
            btn.textContent = 'Create';
        }
    },

    // Leave group
    async leaveGroup() {
        if (!this.currentGroup || !this.isLoggedIn) return;

        if (!confirm('Leave this group?')) return;

        try {
            await DB.leaveGroup(this.user.id, this.currentGroup.id);
            this.currentGroup = null;
            this.renderGroups();
            this.showScreen('groups');
        } catch (e) {
            alert('Failed to leave group: ' + e.message);
        }
    },

    // ==================== BOTTOM NAVIGATION ====================

    // Bind bottom nav events
    bindBottomNavEvents() {
        const bottomNav = document.getElementById('bottom-nav');
        bottomNav.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => {
                const screen = item.dataset.screen;
                if (screen === 'home') {
                    this.updateRankDisplay();
                } else if (screen === 'add-type') {
                    this.newTask = {};
                    this.fromTemplate = false;
                    this.updateTemplateButtonVisibility();
                } else if (screen === 'gallery') {
                    this.renderGallery();
                } else if (screen === 'profile') {
                    this.renderProfile();
                }
                this.showScreen(screen);
            });
        });

        // Floating notification bell
        document.getElementById('floating-notification-bell').addEventListener('click', () => {
            this.showScreen('notifications');
        });
    },

    // Update bottom nav visibility and active state
    updateBottomNav(screenId) {
        const bottomNav = document.getElementById('bottom-nav');
        const floatingBell = document.getElementById('floating-notification-bell');
        const activeScreen = document.getElementById(`screen-${screenId}`);

        // Hide nav on certain screens
        if (this.hideNavScreens.includes(screenId)) {
            bottomNav.classList.add('hidden');
            floatingBell.classList.add('hidden');
            if (activeScreen) {
                activeScreen.classList.remove('has-bottom-nav');
            }
        } else {
            bottomNav.classList.remove('hidden');
            if (activeScreen) {
                activeScreen.classList.add('has-bottom-nav');
            }

            // Show floating bell only on home screen
            if (screenId === 'home') {
                floatingBell.classList.remove('hidden');
            } else {
                floatingBell.classList.add('hidden');
            }

            // Update active state
            bottomNav.querySelectorAll('.nav-item').forEach(item => {
                const navScreen = item.dataset.screen;
                // Check if current screen matches or is a sub-screen
                const isAddScreen = screenId.startsWith('add-') || screenId.startsWith('multi-') || screenId === 'import' || screenId === 'import-review' || screenId === 'import-setup' || screenId === 'templates';
                const isActive = navScreen === screenId ||
                    (navScreen === 'home' && screenId === 'home') ||
                    (navScreen === 'profile' && ['groups', 'leaderboard'].includes(screenId)) ||
                    (navScreen === 'add-type' && isAddScreen);
                item.classList.toggle('active', isActive);
            });

            // Update notification badge
            this.updateNotificationBadge();
        }
    },

    // Get notifications (due soon, overdue, leaderboard changes)
    getNotifications() {
        const notifications = [];
        const tasks = Storage.getTasks();
        const now = new Date();
        now.setHours(0, 0, 0, 0);

        tasks.forEach(task => {
            if (!task.dueDate) return;

            const daysUntil = Storage.getDaysUntilDue(task);
            if (daysUntil === null) return;

            if (daysUntil < 0) {
                notifications.push({
                    type: 'overdue',
                    icon: '⚠️',
                    title: 'Overdue Task',
                    desc: task.name,
                    time: `${Math.abs(daysUntil)} day${Math.abs(daysUntil) !== 1 ? 's' : ''} overdue`,
                    priority: 3,
                    taskId: task.id
                });
            } else if (daysUntil === 0) {
                notifications.push({
                    type: 'due-soon',
                    icon: '📅',
                    title: 'Due Today',
                    desc: task.name,
                    time: 'Due today',
                    priority: 2,
                    taskId: task.id
                });
            } else if (daysUntil === 1) {
                notifications.push({
                    type: 'due-soon',
                    icon: '📅',
                    title: 'Due Tomorrow',
                    desc: task.name,
                    time: 'Due tomorrow',
                    priority: 1,
                    taskId: task.id
                });
            } else if (daysUntil <= 3) {
                notifications.push({
                    type: 'due-soon',
                    icon: '📅',
                    title: 'Coming Up',
                    desc: task.name,
                    time: `Due in ${daysUntil} days`,
                    priority: 0,
                    taskId: task.id
                });
            }
        });

        // Sort by priority (higher = more urgent)
        notifications.sort((a, b) => b.priority - a.priority);

        return notifications;
    },

    // Update notification badge count (uses cache, refreshes every 30s)
    updateNotificationBadge() {
        const now = Date.now();
        if (this._notificationCache !== null && (now - this._notificationCacheTime) < 30000) {
            return; // Use cached badge, don't recalculate
        }
        this._notificationCacheTime = now;
        const notifications = this.getNotifications();
        this._notificationCache = notifications.length;
        const badge = document.getElementById('floating-bell-badge');
        const urgentCount = notifications.filter(n => n.priority >= 2).length;

        if (urgentCount > 0) {
            badge.textContent = urgentCount > 9 ? '9+' : urgentCount;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    },

    // Render notifications screen
    renderNotifications() {
        const notifications = this.getNotifications();
        const container = document.getElementById('notifications-list');
        const noNotifications = document.getElementById('no-notifications');

        if (notifications.length === 0) {
            container.classList.add('hidden');
            noNotifications.classList.remove('hidden');
            return;
        }

        container.classList.remove('hidden');
        noNotifications.classList.add('hidden');

        container.innerHTML = notifications.map(n => `
            <div class="notification-item" data-task-id="${n.taskId || ''}">
                <div class="notification-icon ${n.type}">
                    ${n.icon}
                </div>
                <div class="notification-content">
                    <div class="notification-title">${this.escapeHtml(n.title)}</div>
                    <div class="notification-desc">${this.escapeHtml(n.desc)}</div>
                    <div class="notification-time">${n.time}</div>
                </div>
            </div>
        `).join('');

        // Use event delegation for notification clicks
        if (!container._delegated) {
            container._delegated = true;
            container.addEventListener('click', (e) => {
                const item = e.target.closest('.notification-item');
                if (item && item.dataset.taskId) {
                    const task = Storage.getTasks().find(t => t.id === item.dataset.taskId);
                    if (task) {
                        this.acceptedTask = task;
                        this.showAcceptedTask();
                    }
                }
            });
        }
    },

    // ==================== NOTIFICATION HANDLING ====================

    // Bind notification events
    bindNotificationEvents() {
        // Permission modal buttons
        document.getElementById('btn-enable-notifications').addEventListener('click', async () => {
            await this.enableNotifications();
            document.getElementById('modal-notification-permission').classList.add('hidden');
        });

        document.getElementById('btn-skip-notifications').addEventListener('click', () => {
            document.getElementById('modal-notification-permission').classList.add('hidden');
            // Remember that user declined
            localStorage.setItem('whatnow_notification_prompt_shown', 'true');
        });

        // Profile enable notifications button
        document.getElementById('btn-enable-notifications-profile').addEventListener('click', async () => {
            await this.enableNotifications();
            this.renderProfile();
        });
    },

    // Check if we should prompt for notifications
    shouldPromptForNotifications() {
        if (typeof NotificationManager === 'undefined') return false;
        if (!NotificationManager.isSupported()) return false;
        if (NotificationManager.getPermission() === 'granted') return false;
        if (NotificationManager.getPermission() === 'denied') return false;
        if (localStorage.getItem('whatnow_notification_prompt_shown') === 'true') return false;
        return true;
    },

    // Show notification permission prompt
    showNotificationPrompt() {
        if (!this.shouldPromptForNotifications()) return;
        document.getElementById('modal-notification-permission').classList.remove('hidden');
    },

    // Enable notifications
    async enableNotifications() {
        if (typeof NotificationManager === 'undefined') return false;

        const permission = await NotificationManager.requestPermission();
        if (permission === 'granted') {
            // Schedule reminders for existing tasks with due dates
            const tasks = Storage.getTasks();
            tasks.forEach(task => {
                if (task.dueDate) {
                    NotificationManager.scheduleDueDateReminders(task);
                }
            });
            return true;
        }
        return false;
    },

    // Schedule notifications for a newly saved task
    scheduleTaskNotifications(task) {
        if (typeof NotificationManager === 'undefined') return;
        if (NotificationManager.getPermission() !== 'granted') return;
        if (!task.dueDate) return;

        NotificationManager.scheduleDueDateReminders(task);
    },

    // Render calendar screen
    renderCalendar() {
        const tasks = Storage.getTasks();
        const completed = Storage.getCompletedTasks();

        // Upcoming tasks with due dates
        const upcoming = tasks
            .filter(t => t.dueDate)
            .map(t => ({
                ...t,
                daysUntil: Storage.getDaysUntilDue(t),
                isOverdue: Storage.isOverdue(t)
            }))
            .sort((a, b) => {
                if (a.isOverdue && !b.isOverdue) return -1;
                if (!a.isOverdue && b.isOverdue) return 1;
                return (a.daysUntil || 0) - (b.daysUntil || 0);
            });

        const upcomingContainer = document.getElementById('calendar-upcoming');
        const noUpcoming = document.getElementById('no-upcoming');

        if (upcoming.length === 0) {
            upcomingContainer.classList.add('hidden');
            noUpcoming.classList.remove('hidden');
        } else {
            upcomingContainer.classList.remove('hidden');
            noUpcoming.classList.add('hidden');

            upcomingContainer.innerHTML = upcoming.slice(0, 10).map(task => {
                const date = new Date(task.dueDate);
                const day = date.getDate();
                const month = date.toLocaleString('default', { month: 'short' });

                return `
                    <div class="calendar-item${task.isOverdue ? ' overdue' : ''}" data-id="${task.id}">
                        <div class="calendar-item-date">
                            <div class="date-day">${day}</div>
                            <div class="date-month">${month}</div>
                        </div>
                        <div class="calendar-item-content">
                            <div class="calendar-item-name">${this.escapeHtml(task.name)}</div>
                            <div class="calendar-item-meta">${task.type} · ${task.time} min</div>
                        </div>
                        <button class="task-start-btn" data-id="${task.id}">Start</button>
                        <button class="task-item-delete" data-id="${task.id}">×</button>
                    </div>
                `;
            }).join('');

            // Event delegation for calendar items
            upcomingContainer.addEventListener('click', (e) => {
                const startBtn = e.target.closest('.task-start-btn');
                if (startBtn) {
                    e.stopPropagation();
                    const task = Storage.getTasks().find(t => t.id === startBtn.dataset.id);
                    if (task) {
                        this.acceptedTask = task;
                        this.showAcceptedTask();
                    }
                    return;
                }
                const deleteBtn = e.target.closest('.task-item-delete');
                if (deleteBtn) {
                    e.stopPropagation();
                    if (confirm('Are you sure you want to delete this task?')) {
                        Storage.deleteTask(deleteBtn.dataset.id);
                        this.syncToCloud('delete', deleteBtn.dataset.id);
                        this._notificationCache = null;
                        this.renderCalendar();
                    }
                    return;
                }
                const calItem = e.target.closest('.calendar-item');
                if (calItem) {
                    this.openEditTask(calItem.dataset.id);
                }
            });
        }

        // Recently completed
        const recentCompleted = completed.slice(-10).reverse();
        const completedContainer = document.getElementById('calendar-completed');
        const noCompleted = document.getElementById('no-recent-completed');

        if (recentCompleted.length === 0) {
            completedContainer.classList.add('hidden');
            noCompleted.classList.remove('hidden');
        } else {
            completedContainer.classList.remove('hidden');
            noCompleted.classList.add('hidden');

            completedContainer.innerHTML = recentCompleted.map(task => {
                const date = new Date(task.completedAt);
                const day = date.getDate();
                const month = date.toLocaleString('default', { month: 'short' });

                return `
                    <div class="calendar-item completed">
                        <div class="calendar-item-date">
                            <div class="date-day">${day}</div>
                            <div class="date-month">${month}</div>
                        </div>
                        <div class="calendar-item-content">
                            <div class="calendar-item-name">${this.escapeHtml(task.name)}</div>
                            <div class="calendar-item-meta">${task.type} · +${task.points} pts</div>
                        </div>
                    </div>
                `;
            }).join('');
        }
    }
};

// Start the app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});
