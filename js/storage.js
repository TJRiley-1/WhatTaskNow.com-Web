// Storage module for What Now? app
const Storage = {
    KEYS: {
        TASKS: 'whatnow_tasks',
        TASK_TYPES: 'whatnow_types',
        STATS: 'whatnow_stats',
        TEMPLATES: 'whatnow_templates',
        COMPLETED: 'whatnow_completed',
        PENDING_IMPORT: 'whatnow_pending_import'
    },

    // Default task types
    DEFAULT_TYPES: [
        'Chores',
        'Work',
        'Health',
        'Admin',
        'Errand',
        'Self-care',
        'Creative',
        'Social'
    ],

    // Fallback tasks when no user tasks match
    FALLBACK_TASKS: [
        { name: 'Go for a short walk', desc: 'Fresh air helps clear the mind', type: 'Health', time: 15, social: 'low', energy: 'low' },
        { name: 'Check the post', desc: 'Quick and easy win', type: 'Errand', time: 5, social: 'low', energy: 'low' },
        { name: 'Hoover one room', desc: 'Just one room, not the whole house', type: 'Chores', time: 15, social: 'low', energy: 'medium' },
        { name: 'Do the dishes', desc: 'Clear the sink, clear the mind', type: 'Chores', time: 15, social: 'low', energy: 'low' },
        { name: 'Drink a glass of water', desc: 'Stay hydrated', type: 'Health', time: 5, social: 'low', energy: 'low' },
        { name: 'Stretch for 5 minutes', desc: 'Your body will thank you', type: 'Health', time: 5, social: 'low', energy: 'low' },
        { name: 'Tidy your desk', desc: 'A clear space for a clear mind', type: 'Chores', time: 15, social: 'low', energy: 'low' },
        { name: 'Take out the rubbish', desc: 'One less thing to think about', type: 'Chores', time: 5, social: 'low', energy: 'low' },
        { name: 'Water the plants', desc: 'They need you', type: 'Chores', time: 5, social: 'low', energy: 'low' },
        { name: 'Reply to one message', desc: 'Just one, you can do it', type: 'Social', time: 5, social: 'medium', energy: 'low' },
        { name: 'Make your bed', desc: 'Start with a quick win', type: 'Chores', time: 5, social: 'low', energy: 'low' },
        { name: 'Clear kitchen counter', desc: 'Just the counter, nothing else', type: 'Chores', time: 10, social: 'low', energy: 'low' }
    ],

    // Initialize storage with defaults if needed
    init() {
        if (!localStorage.getItem(this.KEYS.TASK_TYPES)) {
            localStorage.setItem(this.KEYS.TASK_TYPES, JSON.stringify(this.DEFAULT_TYPES));
        }
        if (!localStorage.getItem(this.KEYS.TASKS)) {
            localStorage.setItem(this.KEYS.TASKS, JSON.stringify([]));
        }
        if (!localStorage.getItem(this.KEYS.STATS)) {
            localStorage.setItem(this.KEYS.STATS, JSON.stringify({
                completed: 0,
                skipped: 0,
                totalPoints: 0,
                totalTimeSpent: 0,
                pointsHistory: []
            }));
        } else {
            // Migrate existing stats to include new fields
            const stats = JSON.parse(localStorage.getItem(this.KEYS.STATS));
            if (stats.totalPoints === undefined) {
                stats.totalPoints = 0;
                stats.totalTimeSpent = 0;
                stats.pointsHistory = [];
                localStorage.setItem(this.KEYS.STATS, JSON.stringify(stats));
            }
        }
        if (!localStorage.getItem(this.KEYS.TEMPLATES)) {
            localStorage.setItem(this.KEYS.TEMPLATES, JSON.stringify([]));
        }
        if (!localStorage.getItem(this.KEYS.COMPLETED)) {
            localStorage.setItem(this.KEYS.COMPLETED, JSON.stringify([]));
        }
        if (!localStorage.getItem(this.KEYS.PENDING_IMPORT)) {
            localStorage.setItem(this.KEYS.PENDING_IMPORT, JSON.stringify([]));
        }
    },

    // Task Types
    getTaskTypes() {
        return JSON.parse(localStorage.getItem(this.KEYS.TASK_TYPES)) || this.DEFAULT_TYPES;
    },

    addTaskType(type) {
        const types = this.getTaskTypes();
        if (!types.includes(type)) {
            types.push(type);
            localStorage.setItem(this.KEYS.TASK_TYPES, JSON.stringify(types));
        }
        return types;
    },

    removeTaskType(type) {
        const types = this.getTaskTypes().filter(t => t !== type);
        localStorage.setItem(this.KEYS.TASK_TYPES, JSON.stringify(types));
        return types;
    },

    // Tasks
    getTasks() {
        return JSON.parse(localStorage.getItem(this.KEYS.TASKS)) || [];
    },

    addTask(task) {
        const tasks = this.getTasks();
        task.id = Date.now().toString();
        task.created = new Date().toISOString();
        task.timesShown = 0;
        task.timesSkipped = 0;
        task.timesCompleted = 0;
        tasks.push(task);
        localStorage.setItem(this.KEYS.TASKS, JSON.stringify(tasks));
        return task;
    },

    updateTask(id, updates) {
        const tasks = this.getTasks();
        const index = tasks.findIndex(t => t.id === id);
        if (index !== -1) {
            tasks[index] = { ...tasks[index], ...updates };
            localStorage.setItem(this.KEYS.TASKS, JSON.stringify(tasks));
            return tasks[index];
        }
        return null;
    },

    deleteTask(id) {
        const tasks = this.getTasks().filter(t => t.id !== id);
        localStorage.setItem(this.KEYS.TASKS, JSON.stringify(tasks));
        return tasks;
    },

    // Calculate urgency score based on due date
    getUrgencyScore(task) {
        if (!task.dueDate) return 0;

        const now = new Date();
        now.setHours(0, 0, 0, 0);
        const due = new Date(task.dueDate);
        due.setHours(0, 0, 0, 0);

        const daysUntilDue = Math.ceil((due - now) / (1000 * 60 * 60 * 24));

        if (daysUntilDue < 0) return 4; // Overdue
        if (daysUntilDue <= 1) return 3; // Due today or tomorrow
        if (daysUntilDue <= 3) return 2; // Due in 3 days
        if (daysUntilDue <= 7) return 1; // Due in a week
        return 0;
    },

    // Check if task is overdue
    isOverdue(task) {
        if (!task.dueDate) return false;
        const now = new Date();
        now.setHours(0, 0, 0, 0);
        const due = new Date(task.dueDate);
        due.setHours(0, 0, 0, 0);
        return due < now;
    },

    // Get days until due
    getDaysUntilDue(task) {
        if (!task.dueDate) return null;
        const now = new Date();
        now.setHours(0, 0, 0, 0);
        const due = new Date(task.dueDate);
        due.setHours(0, 0, 0, 0);
        return Math.ceil((due - now) / (1000 * 60 * 60 * 24));
    },

    // Calculate next due date for recurring task
    getNextDueDate(task) {
        if (!task.recurring || task.recurring === 'none') return null;

        const lastDue = task.dueDate ? new Date(task.dueDate) : new Date();
        const nextDue = new Date(lastDue);

        switch (task.recurring) {
            case 'daily':
                nextDue.setDate(nextDue.getDate() + 1);
                break;
            case 'weekly':
                nextDue.setDate(nextDue.getDate() + 7);
                break;
            case 'monthly':
                nextDue.setMonth(nextDue.getMonth() + 1);
                break;
        }

        return nextDue.toISOString().split('T')[0];
    },

    // Find matching tasks based on current state
    findMatchingTasks(energy, social, time) {
        const tasks = this.getTasks();
        const energyLevels = { low: 1, medium: 2, high: 3 };
        const socialLevels = { low: 1, medium: 2, high: 3 };

        // Filter tasks that match current state
        // Task requires X energy/social, user has Y - user can do task if Y >= X
        const matching = tasks.filter(task => {
            const energyMatch = energyLevels[energy] >= energyLevels[task.energy];
            const socialMatch = socialLevels[social] >= socialLevels[task.social];
            const timeMatch = time >= task.time;
            return energyMatch && socialMatch && timeMatch;
        });

        // Sort by urgency first, then times skipped, then times shown
        matching.sort((a, b) => {
            // Urgency (higher = more urgent)
            const urgencyDiff = this.getUrgencyScore(b) - this.getUrgencyScore(a);
            if (urgencyDiff !== 0) return urgencyDiff;

            // Times skipped (prioritize avoided tasks)
            const skipDiff = b.timesSkipped - a.timesSkipped;
            if (skipDiff !== 0) return skipDiff;

            // Times shown (prioritize less shown)
            return a.timesShown - b.timesShown;
        });

        return matching;
    },

    // Get fallback tasks that match current state
    getFallbackTasks(energy, social, time) {
        const energyLevels = { low: 1, medium: 2, high: 3 };
        const socialLevels = { low: 1, medium: 2, high: 3 };

        return this.FALLBACK_TASKS.filter(task => {
            const energyMatch = energyLevels[energy] >= energyLevels[task.energy];
            const socialMatch = socialLevels[social] >= socialLevels[task.social];
            const timeMatch = time >= task.time;
            return energyMatch && socialMatch && timeMatch;
        }).map(task => ({
            ...task,
            id: 'fallback_' + Math.random().toString(36).substr(2, 9),
            isFallback: true
        }));
    },

    // Templates
    getTemplates() {
        return JSON.parse(localStorage.getItem(this.KEYS.TEMPLATES)) || [];
    },

    addTemplate(template) {
        const templates = this.getTemplates();
        template.id = 'tpl_' + Date.now().toString();
        template.created = new Date().toISOString();
        templates.push(template);
        localStorage.setItem(this.KEYS.TEMPLATES, JSON.stringify(templates));
        return template;
    },

    deleteTemplate(id) {
        const templates = this.getTemplates().filter(t => t.id !== id);
        localStorage.setItem(this.KEYS.TEMPLATES, JSON.stringify(templates));
        return templates;
    },

    // Completed tasks history
    getCompletedTasks() {
        return JSON.parse(localStorage.getItem(this.KEYS.COMPLETED)) || [];
    },

    addCompletedTask(task, points, timeSpent) {
        const completed = this.getCompletedTasks();
        completed.push({
            id: 'cpl_' + Date.now().toString(),
            name: task.name,
            type: task.type,
            points: points,
            timeSpent: timeSpent || null,
            completedAt: new Date().toISOString()
        });
        // Keep only last 200 entries to avoid storage bloat
        if (completed.length > 200) {
            completed.splice(0, completed.length - 200);
        }
        localStorage.setItem(this.KEYS.COMPLETED, JSON.stringify(completed));
        return completed;
    },

    // Fun comparisons for stats
    TIME_COMPARISONS: [
        { hours: 1, text: 'enough to watch a movie' },
        { hours: 5, text: 'a full workday of productivity' },
        { hours: 10, text: 'the time to read a novel' },
        { hours: 24, text: 'a full day of focus' },
        { hours: 50, text: 'enough to learn a new skill' },
        { hours: 100, text: 'the fastest time to cycle around the world... almost!' },
        { hours: 200, text: 'more than a week of non-stop work' }
    ],

    TASK_COMPARISONS: [
        { count: 10, text: 'a playlist of wins' },
        { count: 25, text: 'almost a month of daily tasks' },
        { count: 50, text: 'a deck of cards worth of tasks' },
        { count: 100, text: 'a century of accomplishments' },
        { count: 200, text: 'more tasks than days in most years' },
        { count: 365, text: 'a full year of daily achievements' },
        { count: 500, text: 'half a thousand victories' }
    ],

    getTimeComparison(minutes) {
        const hours = minutes / 60;
        let comparison = null;
        for (const c of this.TIME_COMPARISONS) {
            if (hours >= c.hours) {
                comparison = c;
            }
        }
        return comparison;
    },

    getTaskComparison(count) {
        let comparison = null;
        for (const c of this.TASK_COMPARISONS) {
            if (count >= c.count) {
                comparison = c;
            }
        }
        return comparison;
    },

    // Pending imports
    getPendingImports() {
        return JSON.parse(localStorage.getItem(this.KEYS.PENDING_IMPORT)) || [];
    },

    addPendingImport(name) {
        const pending = this.getPendingImports();
        pending.push({
            id: 'imp_' + Date.now().toString() + '_' + Math.random().toString(36).substr(2, 5),
            name: name.trim(),
            created: new Date().toISOString()
        });
        localStorage.setItem(this.KEYS.PENDING_IMPORT, JSON.stringify(pending));
        return pending;
    },

    removePendingImport(id) {
        const pending = this.getPendingImports().filter(p => p.id !== id);
        localStorage.setItem(this.KEYS.PENDING_IMPORT, JSON.stringify(pending));
        return pending;
    },

    clearPendingImports() {
        localStorage.setItem(this.KEYS.PENDING_IMPORT, JSON.stringify([]));
    },

    // Parse imported text
    parseImportText(text) {
        const lines = text.split('\n');
        const tasks = [];

        for (let line of lines) {
            // Strip common prefixes: bullets, numbers, checkboxes
            line = line.trim();
            if (!line) continue;

            // Remove common list markers
            line = line.replace(/^[-*•◦▪️◾️✓✔☐☑□■●○]\s*/, '');  // Bullets
            line = line.replace(/^\d+[.)]\s*/, '');  // Numbered lists
            line = line.replace(/^\[[ x]?\]\s*/i, '');  // Checkboxes [ ], [x], [X]

            line = line.trim();
            if (line && line.length > 0 && line.length <= 100) {
                tasks.push(line);
            }
        }

        return tasks;
    },

    // Parse CSV
    parseCSV(text) {
        const lines = text.split('\n');
        if (lines.length < 2) return []; // Need header + at least one row

        const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
        const nameIndex = headers.findIndex(h => h === 'name' || h === 'task' || h === 'title');

        if (nameIndex === -1) {
            // No name column found, treat each line as a task name
            return lines.slice(1).map(l => l.split(',')[0].trim()).filter(n => n);
        }

        const tasks = [];
        for (let i = 1; i < lines.length; i++) {
            const values = lines[i].split(',');
            const name = values[nameIndex]?.trim();
            if (name) {
                tasks.push(name);
            }
        }

        return tasks;
    },

    // Stats
    getStats() {
        return JSON.parse(localStorage.getItem(this.KEYS.STATS)) || {
            completed: 0,
            skipped: 0,
            totalPoints: 0,
            totalTimeSpent: 0,
            pointsHistory: []
        };
    },

    incrementCompleted() {
        const stats = this.getStats();
        stats.completed++;
        localStorage.setItem(this.KEYS.STATS, JSON.stringify(stats));
        return stats;
    },

    incrementSkipped() {
        const stats = this.getStats();
        stats.skipped++;
        localStorage.setItem(this.KEYS.STATS, JSON.stringify(stats));
        return stats;
    },

    // Points calculation
    // Formula: timePoints[time] + levelPoints[social] + levelPoints[energy]
    // Range: 15 (5min/low/low) to 65 (60min/high/high)
    TIME_POINTS: { 5: 5, 15: 10, 30: 15, 60: 25 },
    LEVEL_POINTS: { low: 5, medium: 10, high: 20 },

    calculatePoints(task) {
        const timePoints = this.TIME_POINTS[task.time] || 10;
        const socialPoints = this.LEVEL_POINTS[task.social] || 5;
        const energyPoints = this.LEVEL_POINTS[task.energy] || 5;
        return timePoints + socialPoints + energyPoints;
    },

    addPoints(points, taskName) {
        const stats = this.getStats();
        stats.totalPoints += points;
        stats.pointsHistory.push({
            date: new Date().toISOString(),
            points: points,
            taskName: taskName
        });
        // Keep only last 100 entries to avoid storage bloat
        if (stats.pointsHistory.length > 100) {
            stats.pointsHistory = stats.pointsHistory.slice(-100);
        }
        localStorage.setItem(this.KEYS.STATS, JSON.stringify(stats));
        return stats;
    },

    addTimeSpent(minutes) {
        const stats = this.getStats();
        stats.totalTimeSpent += minutes;
        localStorage.setItem(this.KEYS.STATS, JSON.stringify(stats));
        return stats;
    },

    // Rank system
    RANKS: [
        { name: 'Task Newbie', minPoints: 0 },
        { name: 'Task Apprentice', minPoints: 100 },
        { name: 'Task Warrior', minPoints: 500 },
        { name: 'Task Hero', minPoints: 1000 },
        { name: 'Task Master', minPoints: 2500 },
        { name: 'Task Legend', minPoints: 5000 }
    ],

    getRank(points) {
        let rank = this.RANKS[0];
        for (const r of this.RANKS) {
            if (points >= r.minPoints) {
                rank = r;
            }
        }
        return rank;
    },

    getNextRank(points) {
        for (const r of this.RANKS) {
            if (points < r.minPoints) {
                return r;
            }
        }
        return null; // Already at max rank
    }
};

// Initialize on load
Storage.init();
