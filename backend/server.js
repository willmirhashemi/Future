/**
 * Endless Future Backend Server
 *
 * Secure proxy server for handling Gemini AI API calls.
 * Keeps API keys secure on the server side, never exposed to clients.
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

// CORS configuration
const corsOptions = {
    origin: process.env.ALLOWED_ORIGINS
        ? process.env.ALLOWED_ORIGINS.split(',')
        : '*',
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 30,
    message: { error: 'Too many requests, please try again later.' }
});
app.use('/api/', limiter);

// Gemini API configuration
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';

// Validate API key on startup
if (!GEMINI_API_KEY || GEMINI_API_KEY === 'your_gemini_api_key_here') {
    console.error('ERROR: GEMINI_API_KEY not configured. Please set it in .env file');
    process.exit(1);
}

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'endless-future-backend',
        timestamp: new Date().toISOString()
    });
});

/**
 * Generate a goal-based plan using Gemini AI
 * POST /api/v1/plan/generate
 */
app.post('/api/v1/plan/generate', async (req, res) => {
    try {
        const {
            identityType,
            customIdentityName,
            timeHorizon,
            availability,
            intensity,
            planConfidence,
            isFirstWeek,
            startDate
        } = req.body;

        // Build the prompt for Gemini
        const prompt = buildPlanGenerationPrompt({
            identityType,
            customIdentityName,
            timeHorizon,
            availability,
            intensity,
            planConfidence,
            isFirstWeek,
            startDate
        });

        // Call Gemini API
        const geminiResponse = await callGeminiAPI(prompt);

        // Parse and structure the response
        const planResponse = parseGeminiPlanResponse(geminiResponse, startDate, timeHorizon);

        res.json(planResponse);
    } catch (error) {
        console.error('Plan generation error:', error);
        res.status(500).json({
            error: 'Failed to generate plan',
            message: error.message
        });
    }
});

/**
 * Adapt weekly plan based on reflection
 * POST /api/v1/plan/adapt
 */
app.post('/api/v1/plan/adapt', async (req, res) => {
    try {
        const {
            weekNumber,
            weekFeeling,
            obstacle,
            note,
            completionRate,
            engagementRate,
            blocksCompleted,
            blocksSkipped,
            blocksMoved,
            blocksReduced,
            currentPlanConfidence,
            currentBlocks
        } = req.body;

        const prompt = buildAdaptationPrompt({
            weekNumber,
            weekFeeling,
            obstacle,
            note,
            completionRate,
            engagementRate,
            blocksCompleted,
            blocksSkipped,
            blocksMoved,
            blocksReduced,
            currentPlanConfidence
        });

        const geminiResponse = await callGeminiAPI(prompt);
        const adaptResponse = parseGeminiAdaptResponse(geminiResponse);

        res.json(adaptResponse);
    } catch (error) {
        console.error('Plan adaptation error:', error);
        res.status(500).json({
            error: 'Failed to adapt plan',
            message: error.message
        });
    }
});

/**
 * Generic chat endpoint for custom AI interactions
 * POST /api/v1/chat
 */
app.post('/api/v1/chat', async (req, res) => {
    try {
        const { message, context } = req.body;

        if (!message) {
            return res.status(400).json({ error: 'Message is required' });
        }

        const prompt = context
            ? `Context: ${context}\n\nUser: ${message}`
            : message;

        const response = await callGeminiAPI(prompt);

        res.json({
            response: response,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Chat error:', error);
        res.status(500).json({
            error: 'Failed to process chat',
            message: error.message
        });
    }
});

/**
 * Call Gemini API with a prompt
 */
async function callGeminiAPI(prompt) {
    const url = `${GEMINI_API_BASE}/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            contents: [{
                parts: [{ text: prompt }]
            }],
            generationConfig: {
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 8192,
            },
            safetySettings: [
                {
                    category: "HARM_CATEGORY_HARASSMENT",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                    category: "HARM_CATEGORY_HATE_SPEECH",
                    threshold: "BLOCK_MEDIUM_AND_ABOVE"
                }
            ]
        })
    });

    if (!response.ok) {
        const errorData = await response.text();
        throw new Error(`Gemini API error: ${response.status} - ${errorData}`);
    }

    const data = await response.json();

    if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
        throw new Error('Invalid response from Gemini API');
    }

    return data.candidates[0].content.parts[0].text;
}

/**
 * Build the prompt for plan generation
 */
function buildPlanGenerationPrompt(params) {
    const identity = params.customIdentityName || params.identityType;

    return `You are an expert life coach and productivity planner. Create a detailed, actionable plan for someone who wants to become: "${identity}"

User Profile:
- Time Horizon: ${params.timeHorizon}
- Weekly Availability: ${params.availability}
- Desired Intensity: ${params.intensity}
- Plan Confidence: ${params.planConfidence}
- Start Date: ${params.startDate}
- First Week: ${params.isFirstWeek}

Generate a comprehensive plan with the following JSON structure (respond ONLY with valid JSON, no markdown):

{
    "milestones": [
        {
            "title": "Milestone title",
            "description": "What this milestone represents",
            "weekNumber": 1,
            "isCompleted": false
        }
    ],
    "weeklyThemes": [
        {
            "weekNumber": 1,
            "title": "Week theme title",
            "description": "Focus for this week",
            "focusAreas": ["Area 1", "Area 2"]
        }
    ],
    "planBlocks": [
        {
            "title": "Activity title",
            "blockDescription": "What to do",
            "blockType": "focus",
            "startTime": "2024-01-08T09:00:00Z",
            "endTime": "2024-01-08T10:00:00Z",
            "weekNumber": 1,
            "dayOfWeek": 1,
            "aiTip": "Helpful tip for this block",
            "energyLevel": "high",
            "priorityLevel": "high"
        }
    ]
}

Guidelines:
- Create 3-5 milestones spread across the time horizon
- Generate weekly themes for each week
- Create 4-7 plan blocks per week
- Block types: "focus" (deep work), "light" (easy tasks), "habit" (daily routines), "review" (reflection)
- Energy levels: "high", "medium", "low"
- Priority levels: "high", "medium", "low"
- Days: 0=Sunday, 1=Monday, ..., 6=Saturday
- Make activities specific and actionable
- Include varied activities throughout the week
- Consider the user's availability level when scheduling`;
}

/**
 * Build the prompt for plan adaptation
 */
function buildAdaptationPrompt(params) {
    return `You are an expert life coach analyzing someone's weekly progress. Based on their reflection, suggest adaptations to their plan.

Week ${params.weekNumber} Reflection:
- Overall Feeling: ${params.weekFeeling}
- Completion Rate: ${(params.completionRate * 100).toFixed(0)}%
- Engagement Rate: ${(params.engagementRate * 100).toFixed(0)}%
- Blocks Completed: ${params.blocksCompleted}
- Blocks Skipped: ${params.blocksSkipped}
- Blocks Moved: ${params.blocksMoved}
- Blocks Reduced: ${params.blocksReduced}
- Current Plan Confidence: ${params.currentPlanConfidence}
${params.obstacle ? `- Main Obstacle: ${params.obstacle}` : ''}
${params.note ? `- User Note: ${params.note}` : ''}

Respond with valid JSON only (no markdown):

{
    "updatedBlocks": [
        {
            "title": "Adjusted activity",
            "blockDescription": "What to do",
            "blockType": "focus",
            "startTime": "ISO8601 datetime",
            "endTime": "ISO8601 datetime",
            "weekNumber": ${params.weekNumber + 1},
            "dayOfWeek": 1,
            "aiTip": "Supportive tip",
            "energyLevel": "medium",
            "priorityLevel": "medium"
        }
    ],
    "summary": "Brief summary of changes made and why",
    "adjustmentType": "lighter|maintained|increased|restructured"
}

Guidelines:
- If completion < 50%, make the plan lighter
- If completion > 90% and feeling good, consider slight increase
- Address specific obstacles mentioned
- Be encouraging and supportive in the summary
- Keep adjustments realistic and sustainable`;
}

/**
 * Parse Gemini response for plan generation
 */
function parseGeminiPlanResponse(response, startDate, timeHorizon) {
    try {
        // Clean the response - remove any markdown formatting
        let cleaned = response.trim();
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.slice(7);
        }
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.slice(3);
        }
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.slice(0, -3);
        }
        cleaned = cleaned.trim();

        const parsed = JSON.parse(cleaned);

        return {
            milestones: parsed.milestones || [],
            weeklyThemes: parsed.weeklyThemes || [],
            planBlocks: parsed.planBlocks || []
        };
    } catch (error) {
        console.error('Failed to parse Gemini plan response:', error);
        console.error('Raw response:', response);

        // Return a default structure if parsing fails
        return {
            milestones: [],
            weeklyThemes: [],
            planBlocks: []
        };
    }
}

/**
 * Parse Gemini response for plan adaptation
 */
function parseGeminiAdaptResponse(response) {
    try {
        let cleaned = response.trim();
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.slice(7);
        }
        if (cleaned.startsWith('```')) {
            cleaned = cleaned.slice(3);
        }
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.slice(0, -3);
        }
        cleaned = cleaned.trim();

        const parsed = JSON.parse(cleaned);

        return {
            updatedBlocks: parsed.updatedBlocks || [],
            summary: parsed.summary || 'Plan adjusted based on your feedback.',
            adjustmentType: parsed.adjustmentType || 'maintained'
        };
    } catch (error) {
        console.error('Failed to parse Gemini adapt response:', error);

        return {
            updatedBlocks: [],
            summary: 'Unable to process adaptation. Please try again.',
            adjustmentType: 'maintained'
        };
    }
}

// Start server
app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════╗
║          Endless Future Backend Server                     ║
╠═══════════════════════════════════════════════════════════╣
║  Status:    Running                                        ║
║  Port:      ${PORT}                                            ║
║  Mode:      ${process.env.NODE_ENV || 'development'}                                  ║
║  Gemini:    Configured ✓                                   ║
╚═══════════════════════════════════════════════════════════╝

Endpoints:
  GET  /health              - Health check
  POST /api/v1/plan/generate - Generate AI plan
  POST /api/v1/plan/adapt    - Adapt plan based on reflection
  POST /api/v1/chat          - General AI chat
    `);
});

module.exports = app;
