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

    // Initialize the app
    init() {
        this.bindEvents();
        this.renderTaskTypes();
        this.renderEditTaskTypes();
        this.updateRankDisplay();
        this.showScreen('home');
    },

    // Screen navigation
    showScreen(screenId) {
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

        document.getElementById('btn-gallery').addEventListener('click', () => {
            this.renderGallery();
            this.showScreen('gallery');
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

                // Update state
                this.currentState[type] = type === 'time' ? parseInt(value) : value;

                // Update button styles
                const row = btn.parentElement;
                row.querySelectorAll('.state-btn').forEach(b => b.classList.remove('selected'));
                btn.classList.add('selected');

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
            this.showScreen('swipe');
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
                Storage.addTask({
                    name: name,
                    desc: '',
                    type: this.multiAddTask.type,
                    time: this.multiAddTask.time,
                    social: this.multiAddTask.social,
                    energy: this.multiAddTask.energy
                });
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

        // Bind setup buttons
        container.querySelectorAll('.pending-setup-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.openImportSetup(btn.dataset.id);
            });
        });

        // Bind delete buttons
        container.querySelectorAll('.pending-delete-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                Storage.removePendingImport(btn.dataset.id);
                this.renderPendingImports();
            });
        });
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

        Storage.addTask({
            name: this.currentImportTask.name,
            desc: '',
            type: this.importTaskSettings.type,
            time: this.importTaskSettings.time,
            social: this.importTaskSettings.social,
            energy: this.importTaskSettings.energy
        });

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
                this.showScreen('manage');
            }
        });

        // Delete task
        document.getElementById('btn-delete-task').addEventListener('click', () => {
            if (confirm('Delete this task?')) {
                Storage.deleteTask(this.editingTask.id);
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
        if (!task) return;

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

    // Check if all state options are selected
    updateFindButtonState() {
        const allSelected = this.currentState.energy && this.currentState.social && this.currentState.time;
        document.getElementById('btn-find-task').disabled = !allSelected;
    },

    // Render task types
    renderTaskTypes() {
        const container = document.getElementById('task-types');
        const types = Storage.getTaskTypes();

        container.innerHTML = types.map(type => `
            <button class="option-btn type-option" data-value="${type}">${type}</button>
        `).join('');
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

        // Bind template item clicks
        container.querySelectorAll('.template-item').forEach(item => {
            item.addEventListener('click', (e) => {
                if (!e.target.classList.contains('template-item-delete')) {
                    this.useTemplate(item.dataset.id);
                }
            });
        });

        // Bind delete buttons
        container.querySelectorAll('.template-item-delete').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                Storage.deleteTemplate(btn.dataset.id);
                this.renderTemplateList();
                this.updateTemplateButtonVisibility();
            });
        });
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

        Storage.addTask(this.newTask);

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
        const tasks = Storage.getTasks();

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
                    <button class="task-item-delete" data-id="${task.id}">×</button>
                </div>
            `;
        }).join('');

        // Bind task item clicks (for editing)
        container.querySelectorAll('.task-item').forEach(item => {
            item.addEventListener('click', (e) => {
                if (!e.target.classList.contains('task-item-delete')) {
                    this.openEditTask(item.dataset.id);
                }
            });
        });

        // Bind delete buttons
        container.querySelectorAll('.task-item-delete').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                Storage.deleteTask(btn.dataset.id);
                this.renderTaskList();
            });
        });
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

        // Shuffle for variety
        tasks = this.shuffleArray(tasks);

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
            currentX = clientX - startX;

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
        card.addEventListener('touchmove', onMove, { passive: true });
        card.addEventListener('touchend', onEnd);
    },

    // Animate card off screen
    animateCardOut(card, direction) {
        const task = this.matchingTasks[this.currentCardIndex];
        const translateX = direction === 'left' ? -500 : 500;
        const rotation = direction === 'left' ? -30 : 30;

        card.style.transition = 'transform 0.3s ease';
        card.style.transform = `translateX(${translateX}px) rotate(${rotation}deg)`;

        setTimeout(() => {
            if (direction === 'right') {
                // Accepted
                this.acceptedTask = task;
                if (!task.isFallback) {
                    Storage.updateTask(task.id, {
                        timesShown: (task.timesShown || 0) + 1
                    });
                }
                this.showAcceptedTask();
            } else {
                // Skipped
                if (!task.isFallback) {
                    Storage.updateTask(task.id, {
                        timesShown: (task.timesShown || 0) + 1,
                        timesSkipped: (task.timesSkipped || 0) + 1
                    });
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
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
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
            }
        }, 1000);

        // Save timer state to sessionStorage
        sessionStorage.setItem('whatnow_timer', JSON.stringify({
            taskId: this.acceptedTask.id,
            startTime: Date.now(),
            seconds: 0
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
        if (!this.acceptedTask) return;

        // Store previous rank for level-up check
        const stats = Storage.getStats();
        this.previousRank = Storage.getRank(stats.totalPoints);

        // Calculate and award points
        const points = Storage.calculatePoints(this.acceptedTask);
        this.lastPointsEarned = points;

        // Update task stats
        if (!this.acceptedTask.isFallback) {
            const updates = {
                timesCompleted: (this.acceptedTask.timesCompleted || 0) + 1,
                pointsEarned: (this.acceptedTask.pointsEarned || 0) + points
            };

            // Handle recurring tasks - set next due date
            if (this.acceptedTask.recurring && this.acceptedTask.recurring !== 'none') {
                updates.dueDate = Storage.getNextDueDate(this.acceptedTask);
            }

            Storage.updateTask(this.acceptedTask.id, updates);
        }

        // Update global stats
        Storage.incrementCompleted();
        Storage.addPoints(points, this.acceptedTask.name);

        // Track time if timer was used
        let minutesSpent = null;
        if (fromTimer && this.timerSeconds > 0) {
            minutesSpent = Math.ceil(this.timerSeconds / 60);
            Storage.addTimeSpent(minutesSpent);
            this.cancelTimer();
        }

        // Log to completed history
        Storage.addCompletedTask(this.acceptedTask, points, minutesSpent);

        // Show celebration
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
        const canvas = document.getElementById('confetti-canvas');
        const ctx = canvas.getContext('2d');

        // Set canvas size
        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;

        const particles = [];
        const colors = ['#6366f1', '#f59e0b', '#10b981', '#ef4444', '#8b5cf6', '#ec4899'];

        // Create particles
        for (let i = 0; i < 100; i++) {
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
            requestAnimationFrame(animate);
        };

        animate();
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
    }
};

// Start the app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});
