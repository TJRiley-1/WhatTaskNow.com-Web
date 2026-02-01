// Supabase Client Configuration
const SUPABASE_URL = 'https://jntgomnsvixoroponjcx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpudGdvbW5zdml4b3JvcG9uamN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4OTUzMDYsImV4cCI6MjA4NTQ3MTMwNn0.nP6ZmxeOZthqkisBBYXfz8OZrWssuocpLNj5ITs_KIw';

// Simple Supabase client (no build tools needed)
const Supabase = {
    url: SUPABASE_URL,
    key: SUPABASE_ANON_KEY,

    // Current session
    session: null,
    user: null,

    // Initialize
    async init() {
        console.log('[Auth] Initializing Supabase auth...');

        // Check for OAuth callback FIRST (before restoring old session)
        await this.handleAuthCallback();

        // If no session from callback, check for existing session
        if (!this.session) {
            console.log('[Auth] No session from callback, checking localStorage...');
            const storedSession = localStorage.getItem('supabase_session');
            if (storedSession) {
                try {
                    this.session = JSON.parse(storedSession);
                    console.log('[Auth] Found stored session, refreshing...');
                    await this.refreshSession();
                } catch (e) {
                    console.error('[Auth] Error restoring session:', e);
                    this.clearSession();
                }
            }
        }

        // Ensure we have user data if we have a session
        if (this.session && !this.user) {
            console.log('[Auth] Have session but no user, fetching user...');
            await this.getUser();
        }

        console.log('[Auth] Init complete. User:', this.user?.email || 'none');
        return this.user;
    },

    // API request helper
    async request(endpoint, options = {}) {
        const url = `${this.url}${endpoint}`;
        const headers = {
            'apikey': this.key,
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (this.session?.access_token) {
            headers['Authorization'] = `Bearer ${this.session.access_token}`;
        }

        const response = await fetch(url, {
            ...options,
            headers
        });

        if (!response.ok) {
            const error = await response.json().catch(() => ({ message: response.statusText }));
            const errorMsg = error.error_description || error.message || error.msg || 'Request failed';
            // Provide more user-friendly error messages
            if (errorMsg.includes('Invalid login credentials')) {
                throw new Error('Invalid email or password');
            }
            if (errorMsg.includes('Email not confirmed')) {
                throw new Error('Please confirm your email before signing in');
            }
            if (errorMsg.includes('User already registered')) {
                throw new Error('An account with this email already exists');
            }
            throw new Error(errorMsg);
        }

        return response.json();
    },

    // Auth: Sign up with email
    async signUp(email, password, displayName = null) {
        const body = {
            email,
            password,
            data: displayName ? { full_name: displayName } : {}
        };

        const data = await this.request('/auth/v1/signup', {
            method: 'POST',
            body: JSON.stringify(body)
        });

        if (data.access_token) {
            await this.setSession(data);
        }
        return data;
    },

    // Auth: Sign in with email
    async signIn(email, password) {
        const data = await this.request('/auth/v1/token?grant_type=password', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });

        if (data.access_token) {
            await this.setSession(data);
        }
        return data;
    },

    // Auth: Sign in with OAuth (Google)
    async signInWithGoogle() {
        // Use current origin, ensuring we don't redirect to localhost in production
        let redirectTo = window.location.origin;
        // Remove trailing slash and add pathname
        if (window.location.pathname && window.location.pathname !== '/') {
            redirectTo += window.location.pathname.replace(/\/$/, '');
        }
        const url = `${this.url}/auth/v1/authorize?provider=google&redirect_to=${encodeURIComponent(redirectTo)}`;
        window.location.href = url;
    },

    // Auth: Handle OAuth callback
    async handleAuthCallback() {
        const hash = window.location.hash;
        console.log('[Auth] Checking for OAuth callback, hash:', hash);

        // Check for error in hash
        if (hash && hash.includes('error')) {
            const params = new URLSearchParams(hash.substring(1));
            console.error('[Auth] OAuth error:', params.get('error'), params.get('error_description'));
            return;
        }

        if (hash && hash.includes('access_token')) {
            console.log('[Auth] Found access_token in hash, processing...');
            const params = new URLSearchParams(hash.substring(1));
            const access_token = params.get('access_token');
            const refresh_token = params.get('refresh_token');
            const expires_in = params.get('expires_in');

            if (access_token) {
                console.log('[Auth] Setting session with tokens...');
                try {
                    await this.setSession({
                        access_token,
                        refresh_token,
                        expires_in: parseInt(expires_in),
                        expires_at: Date.now() + (parseInt(expires_in) * 1000)
                    });
                    console.log('[Auth] Session set successfully, user:', this.user?.email);
                } catch (e) {
                    console.error('[Auth] Error setting session:', e);
                }

                // Clear the hash
                window.history.replaceState(null, '', window.location.pathname);
            }
        }
    },

    // Auth: Refresh session
    async refreshSession() {
        if (!this.session?.refresh_token) {
            this.clearSession();
            return null;
        }

        try {
            const data = await this.request('/auth/v1/token?grant_type=refresh_token', {
                method: 'POST',
                body: JSON.stringify({ refresh_token: this.session.refresh_token })
            });

            if (data.access_token) {
                await this.setSession(data);
            }
            return this.user;
        } catch (e) {
            this.clearSession();
            return null;
        }
    },

    // Auth: Get current user
    async getUser() {
        if (!this.session?.access_token) return null;

        try {
            const data = await this.request('/auth/v1/user');
            this.user = data;
            return data;
        } catch (e) {
            return null;
        }
    },

    // Auth: Sign out
    async signOut() {
        if (this.session?.access_token) {
            try {
                await this.request('/auth/v1/logout', { method: 'POST' });
            } catch (e) {
                // Ignore errors on logout
            }
        }
        this.clearSession();
    },

    // Session management
    async setSession(data) {
        this.session = {
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_at: data.expires_at || (Date.now() + (data.expires_in * 1000))
        };
        this.user = data.user || null;
        localStorage.setItem('supabase_session', JSON.stringify(this.session));

        // Get user info if not included
        if (!this.user) {
            await this.getUser();
        }
    },

    clearSession() {
        this.session = null;
        this.user = null;
        localStorage.removeItem('supabase_session');
    },

    // Database: Query helper
    async from(table) {
        return new SupabaseQuery(this, table);
    }
};

// Query builder class
class SupabaseQuery {
    constructor(client, table) {
        this.client = client;
        this.table = table;
        this.queryParams = [];
        this.selectColumns = '*';
        this.orderColumn = null;
        this.orderAsc = true;
        this.limitCount = null;
    }

    select(columns = '*') {
        this.selectColumns = columns;
        return this;
    }

    eq(column, value) {
        this.queryParams.push(`${column}=eq.${value}`);
        return this;
    }

    gt(column, value) {
        this.queryParams.push(`${column}=gt.${value}`);
        return this;
    }

    gte(column, value) {
        this.queryParams.push(`${column}=gte.${value}`);
        return this;
    }

    lt(column, value) {
        this.queryParams.push(`${column}=lt.${value}`);
        return this;
    }

    order(column, { ascending = true } = {}) {
        this.orderColumn = column;
        this.orderAsc = ascending;
        return this;
    }

    limit(count) {
        this.limitCount = count;
        return this;
    }

    buildUrl() {
        let url = `/rest/v1/${this.table}?select=${this.selectColumns}`;

        if (this.queryParams.length > 0) {
            url += '&' + this.queryParams.join('&');
        }

        if (this.orderColumn) {
            url += `&order=${this.orderColumn}.${this.orderAsc ? 'asc' : 'desc'}`;
        }

        if (this.limitCount) {
            url += `&limit=${this.limitCount}`;
        }

        return url;
    }

    async execute() {
        const url = this.buildUrl();
        try {
            const data = await this.client.request(url);
            return { data, error: null };
        } catch (e) {
            return { data: null, error: e };
        }
    }

    // Shorthand for execute
    async then(resolve) {
        resolve(await this.execute());
    }

    // Insert
    async insert(data) {
        try {
            const result = await this.client.request(`/rest/v1/${this.table}`, {
                method: 'POST',
                headers: { 'Prefer': 'return=representation' },
                body: JSON.stringify(data)
            });
            return { data: result, error: null };
        } catch (e) {
            return { data: null, error: e };
        }
    }

    // Update
    async update(data) {
        const url = `/rest/v1/${this.table}?${this.queryParams.join('&')}`;
        try {
            const result = await this.client.request(url, {
                method: 'PATCH',
                headers: { 'Prefer': 'return=representation' },
                body: JSON.stringify(data)
            });
            return { data: result, error: null };
        } catch (e) {
            return { data: null, error: e };
        }
    }

    // Delete
    async delete() {
        const url = `/rest/v1/${this.table}?${this.queryParams.join('&')}`;
        try {
            await this.client.request(url, { method: 'DELETE' });
            return { error: null };
        } catch (e) {
            return { error: e };
        }
    }

    // Upsert
    async upsert(data) {
        try {
            const result = await this.client.request(`/rest/v1/${this.table}`, {
                method: 'POST',
                headers: {
                    'Prefer': 'return=representation,resolution=merge-duplicates'
                },
                body: JSON.stringify(data)
            });
            return { data: result, error: null };
        } catch (e) {
            return { data: null, error: e };
        }
    }
}

// Database helper functions
const DB = {
    // Get user profile
    async getProfile(userId) {
        const query = new SupabaseQuery(Supabase, 'profiles');
        return query.eq('id', userId).execute();
    },

    // Update user profile
    async updateProfile(userId, updates) {
        const query = new SupabaseQuery(Supabase, 'profiles');
        return query.eq('id', userId).update({
            ...updates,
            updated_at: new Date().toISOString()
        });
    },

    // Sync tasks to cloud
    async syncTasks(userId, tasks) {
        const cloudTasks = tasks.map(task => ({
            user_id: userId,
            local_id: task.id,
            name: task.name,
            description: task.desc || null,
            type: task.type,
            time: task.time,
            social: task.social,
            energy: task.energy,
            due_date: task.dueDate || null,
            recurring: task.recurring || 'none',
            times_shown: task.timesShown || 0,
            times_skipped: task.timesSkipped || 0,
            times_completed: task.timesCompleted || 0,
            points_earned: task.pointsEarned || 0
        }));

        // Upsert all tasks
        for (const task of cloudTasks) {
            const query = new SupabaseQuery(Supabase, 'tasks');
            await query.upsert(task);
        }
    },

    // Get tasks from cloud
    async getTasks(userId) {
        const query = new SupabaseQuery(Supabase, 'tasks');
        return query.eq('user_id', userId).order('created_at', { ascending: false }).execute();
    },

    // Log completed task
    async logCompleted(userId, taskName, taskType, points, timeSpent) {
        const query = new SupabaseQuery(Supabase, 'completed_tasks');
        return query.insert({
            user_id: userId,
            task_name: taskName,
            task_type: taskType,
            points: points,
            time_spent: timeSpent
        });
    },

    // Get groups for user
    async getMyGroups(userId) {
        const query = new SupabaseQuery(Supabase, 'group_members');
        const { data: memberships, error } = await query.eq('user_id', userId).execute();

        if (error || !memberships?.length) return { data: [], error };

        const groupIds = memberships.map(m => m.group_id);
        const groups = [];

        for (const groupId of groupIds) {
            const groupQuery = new SupabaseQuery(Supabase, 'groups');
            const { data } = await groupQuery.eq('id', groupId).execute();
            if (data?.[0]) groups.push(data[0]);
        }

        return { data: groups, error: null };
    },

    // Create group
    async createGroup(userId, name, description) {
        const inviteCode = Math.random().toString(36).substring(2, 8).toUpperCase();

        const query = new SupabaseQuery(Supabase, 'groups');
        const { data, error } = await query.insert({
            name,
            description,
            invite_code: inviteCode,
            created_by: userId
        });

        if (error) return { data: null, error };

        // Join the group
        const memberQuery = new SupabaseQuery(Supabase, 'group_members');
        await memberQuery.insert({
            group_id: data[0].id,
            user_id: userId
        });

        return { data: data[0], error: null };
    },

    // Join group by code
    async joinGroup(userId, inviteCode) {
        const query = new SupabaseQuery(Supabase, 'groups');
        const { data: groups, error } = await query.eq('invite_code', inviteCode.toUpperCase()).execute();

        if (error || !groups?.length) {
            return { data: null, error: new Error('Invalid invite code') };
        }

        const memberQuery = new SupabaseQuery(Supabase, 'group_members');
        const { error: joinError } = await memberQuery.insert({
            group_id: groups[0].id,
            user_id: userId
        });

        if (joinError) return { data: null, error: joinError };
        return { data: groups[0], error: null };
    },

    // Get leaderboard for group
    async getLeaderboard(groupId) {
        // Get all members of the group
        const memberQuery = new SupabaseQuery(Supabase, 'group_members');
        const { data: members, error: memberError } = await memberQuery.eq('group_id', groupId).execute();

        if (memberError || !members?.length) return { data: [], error: memberError };

        // Get profiles and weekly stats for each member
        const leaderboard = [];
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        for (const member of members) {
            // Get profile
            const { data: profiles } = await DB.getProfile(member.user_id);
            const profile = profiles?.[0];
            if (!profile) continue;

            // Get weekly completed tasks
            const completedQuery = new SupabaseQuery(Supabase, 'completed_tasks');
            const { data: completed } = await completedQuery
                .eq('user_id', member.user_id)
                .gte('completed_at', weekAgo.toISOString())
                .execute();

            const weeklyPoints = completed?.reduce((sum, c) => sum + c.points, 0) || 0;
            const weeklyTasks = completed?.length || 0;

            leaderboard.push({
                user_id: member.user_id,
                display_name: profile.display_name,
                avatar_url: profile.avatar_url,
                current_rank: profile.current_rank,
                weekly_points: weeklyPoints,
                weekly_tasks: weeklyTasks
            });
        }

        // Sort by weekly points
        leaderboard.sort((a, b) => b.weekly_points - a.weekly_points);

        return { data: leaderboard, error: null };
    },

    // Leave group
    async leaveGroup(userId, groupId) {
        const query = new SupabaseQuery(Supabase, 'group_members');
        return query.eq('user_id', userId).eq('group_id', groupId).delete();
    }
};
