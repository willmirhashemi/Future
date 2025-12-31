import Foundation

// MARK: - Domain Knowledge Base
/// Deep, actionable knowledge for each career/goal domain
/// Contains the 20% of actions that produce 80% of results

final class DomainKnowledgeBase {
    static let shared = DomainKnowledgeBase()

    private init() {}

    // MARK: - Get Blueprint

    func getBlueprint(for domain: GoalDomainType) -> DomainBlueprint {
        switch domain {
        case .softwareEngineering: return softwareEngineeringBlueprint
        case .investmentBanking: return investmentBankingBlueprint
        case .fitness: return fitnessBlueprint
        case .weightLoss: return weightLossBlueprint
        case .business: return businessBlueprint
        case .incomeGeneration: return incomeGenerationBlueprint
        case .contentCreation: return contentCreationBlueprint
        case .languageLearning: return languageLearningBlueprint
        case .academicSuccess: return academicSuccessBlueprint
        case .careerTransition: return careerTransitionBlueprint
        case .general: return generalBlueprint
        }
    }

    func getKeywords(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["software", "engineer", "developer", "coding", "programming", "tech", "developer", "app", "web", "mobile", "frontend", "backend", "fullstack", "computer science", "cs", "swe"]
        case .investmentBanking:
            return ["investment banking", "ib", "finance", "wall street", "banking", "analyst", "m&a", "private equity", "pe", "hedge fund", "trading", "goldman", "morgan stanley", "jp morgan"]
        case .fitness:
            return ["fitness", "gym", "workout", "muscle", "strength", "athletic", "bodybuilding", "lift", "training", "exercise", "fit", "gains"]
        case .weightLoss:
            return ["lose weight", "weight loss", "fat", "slim", "diet", "pounds", "lbs", "kg", "lean", "cut", "shred", "belly", "calories"]
        case .business:
            return ["business", "startup", "entrepreneur", "founder", "company", "launch", "product", "customers", "revenue", "saas", "ecommerce"]
        case .incomeGeneration:
            return ["money", "income", "earn", "side hustle", "freelance", "$", "dollars", "k per month", "passive income", "cash", "profit", "rich"]
        case .contentCreation:
            return ["content", "youtube", "tiktok", "instagram", "social media", "creator", "influencer", "followers", "viral", "brand", "audience"]
        case .languageLearning:
            return ["language", "spanish", "french", "german", "chinese", "japanese", "korean", "fluent", "speak", "learn language", "bilingual"]
        case .academicSuccess:
            return ["study", "exam", "gpa", "grades", "university", "college", "degree", "mcat", "lsat", "gmat", "test", "school", "academic"]
        case .careerTransition:
            return ["career change", "switch careers", "transition", "new field", "pivot", "change jobs", "different industry"]
        case .general:
            return ["goal", "improve", "better", "achieve", "success", "growth", "develop"]
        }
    }

    // MARK: - Software Engineering Blueprint

    private var softwareEngineeringBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .softwareEngineering,
            defaultSuccessSummary: "Land a software engineering role with strong technical skills and a compelling portfolio",
            successOutcomes: [
                DomainOutcome(description: "Complete 3+ portfolio projects", metric: "projects", targetValue: 3),
                DomainOutcome(description: "Solve 100+ coding problems", metric: "problems", targetValue: 100),
                DomainOutcome(description: "Receive interview callbacks", metric: "callbacks", targetValue: 5)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Data Structures", beginnerLevel: "Arrays, strings", targetLevel: "Trees, graphs, dynamic programming"),
                PerformanceBenchmark(skill: "System Design", beginnerLevel: "Basic CRUD", targetLevel: "Scalable distributed systems"),
                PerformanceBenchmark(skill: "Coding Speed", beginnerLevel: "60+ min/problem", targetLevel: "20-30 min/medium problem")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "LeetCode Practice",
                    description: "Solve algorithmic problems daily to build pattern recognition",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .earlyMorning]
                ),
                CoreActivity(
                    title: "Project Building",
                    description: "Build real projects that solve problems and demonstrate skills",
                    durationMinutes: 90,
                    frequency: .timesPerWeek(4),
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "System Design Study",
                    description: "Learn to design scalable systems - critical for senior roles",
                    durationMinutes: 45,
                    frequency: .timesPerWeek(3),
                    blockType: .focus,
                    impactScore: 0.80,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Code Review Practice",
                    description: "Review open source code to learn patterns and best practices",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(2),
                    blockType: .light,
                    impactScore: 0.60,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.afternoon, .evening]
                ),
                CoreActivity(
                    title: "Networking & Applications",
                    description: "Apply to jobs, reach out to recruiters, attend meetups",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .habit,
                    impactScore: 0.75,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "The Grind Pattern",
                    description: "Consistent daily coding builds muscle memory faster than sporadic long sessions",
                    tactics: [
                        "Solve 1-2 problems every morning before anything else",
                        "Focus on patterns, not memorization",
                        "Review solutions even when you solve correctly"
                    ],
                    resources: ["LeetCode", "NeetCode roadmap", "Blind 75"]
                ),
                ProvenStrategy(
                    title: "Portfolio That Stands Out",
                    description: "Projects that solve real problems get noticed more than tutorials",
                    tactics: [
                        "Build something you'd actually use",
                        "Deploy everything - live demos matter",
                        "Write clear READMEs with screenshots"
                    ],
                    resources: ["GitHub", "Vercel", "Railway"]
                ),
                ProvenStrategy(
                    title: "Referral Hunting",
                    description: "Referrals have 10x the success rate of cold applications",
                    tactics: [
                        "Message engineers on LinkedIn with specific questions",
                        "Attend local meetups and hackathons",
                        "Contribute to open source for visibility"
                    ],
                    resources: ["LinkedIn", "Meetup.com", "Discord communities"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...4, focus: "Core data structures and first project"),
                ProgressionPhase(name: "Building", weekRange: 5...8, focus: "Advanced algorithms and portfolio expansion"),
                ProgressionPhase(name: "Interview Prep", weekRange: 9...12, focus: "Mock interviews and system design"),
                ProgressionPhase(name: "Execution", weekRange: 13...16, focus: "Active applications and networking")
            ]
        )
    }

    // MARK: - Investment Banking Blueprint

    private var investmentBankingBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .investmentBanking,
            defaultSuccessSummary: "Secure an investment banking offer through technical mastery and strategic networking",
            successOutcomes: [
                DomainOutcome(description: "Build 20+ meaningful connections", metric: "connections", targetValue: 20),
                DomainOutcome(description: "Complete 50+ technical questions", metric: "questions", targetValue: 50),
                DomainOutcome(description: "Secure interview invitations", metric: "interviews", targetValue: 5)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Financial Modeling", beginnerLevel: "Basic Excel", targetLevel: "Full 3-statement model"),
                PerformanceBenchmark(skill: "Valuation", beginnerLevel: "Conceptual", targetLevel: "DCF, Comps, Precedents"),
                PerformanceBenchmark(skill: "Deal Knowledge", beginnerLevel: "None", targetLevel: "Discuss 5+ recent deals fluently")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Technical Prep",
                    description: "Master accounting, valuation, and financial modeling concepts",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning, .earlyMorning]
                ),
                CoreActivity(
                    title: "Networking Outreach",
                    description: "Cold emails and LinkedIn messages to bankers and alumni",
                    durationMinutes: 30,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.95,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.morning, .evening]
                ),
                CoreActivity(
                    title: "Deal Analysis",
                    description: "Study recent M&A deals and be ready to discuss them",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .light,
                    impactScore: 0.70,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.afternoon]
                ),
                CoreActivity(
                    title: "Behavioral Story Prep",
                    description: "Craft and refine your story - why banking, why this firm",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(2),
                    blockType: .light,
                    impactScore: 0.85,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                ),
                CoreActivity(
                    title: "Mock Interviews",
                    description: "Practice with peers or mentors under pressure",
                    durationMinutes: 60,
                    frequency: .timesPerWeek(2),
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.afternoon, .evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "The Networking Funnel",
                    description: "Networking is the #1 factor - technical skills get you through, networking gets you in",
                    tactics: [
                        "Send 5 cold emails per day to alumni and bankers",
                        "Always ask for 15-minute calls, not jobs",
                        "Follow up within 24 hours with thank you notes"
                    ],
                    resources: ["LinkedIn Sales Navigator", "Alumni database", "Wall Street Oasis"]
                ),
                ProvenStrategy(
                    title: "Technical Mastery",
                    description: "Flawless technicals build confidence and impress interviewers",
                    tactics: [
                        "Memorize the key formulas until they're automatic",
                        "Build your own models to truly understand them",
                        "Practice explaining concepts out loud"
                    ],
                    resources: ["Breaking Into Wall Street", "Wall Street Prep", "Rosenbaum & Pearl"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...3, focus: "Accounting and basic valuation"),
                ProgressionPhase(name: "Technical Deep Dive", weekRange: 4...6, focus: "Modeling and advanced valuation"),
                ProgressionPhase(name: "Network Building", weekRange: 7...10, focus: "Aggressive outreach and coffee chats"),
                ProgressionPhase(name: "Interview Mode", weekRange: 11...14, focus: "Mock interviews and applications")
            ]
        )
    }

    // MARK: - Fitness Blueprint

    private var fitnessBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .fitness,
            defaultSuccessSummary: "Build a stronger, more capable body through consistent training and smart recovery",
            successOutcomes: [
                DomainOutcome(description: "Complete workouts consistently", metric: "workouts/week", targetValue: 4),
                DomainOutcome(description: "Progressive strength gains", metric: "strength increase %", targetValue: 20),
                DomainOutcome(description: "Establish lasting habits", metric: "weeks consistent", targetValue: 12)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Workout Consistency", beginnerLevel: "1-2x/week", targetLevel: "4-5x/week"),
                PerformanceBenchmark(skill: "Form Quality", beginnerLevel: "Learning", targetLevel: "Solid on all compounds"),
                PerformanceBenchmark(skill: "Recovery", beginnerLevel: "Irregular sleep", targetLevel: "7+ hours, active recovery")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Strength Training",
                    description: "Compound movements: squat, deadlift, bench, rows, overhead press",
                    durationMinutes: 60,
                    frequency: .timesPerWeek(4),
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Cardio/Conditioning",
                    description: "Heart health and endurance - walking, running, or HIIT",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .habit,
                    impactScore: 0.70,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.earlyMorning, .evening]
                ),
                CoreActivity(
                    title: "Meal Prep",
                    description: "Prepare protein-rich meals to hit nutrition goals",
                    durationMinutes: 60,
                    frequency: .timesPerWeek(2),
                    blockType: .light,
                    impactScore: 0.85,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.afternoon, .evening]
                ),
                CoreActivity(
                    title: "Mobility & Recovery",
                    description: "Stretching, foam rolling, active recovery",
                    durationMinutes: 20,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.60,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.evening, .morning]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Progressive Overload",
                    description: "Gradually increase weight/reps to force adaptation",
                    tactics: [
                        "Add 5lbs to lifts when you hit rep targets",
                        "Track every workout - what gets measured improves",
                        "Deload every 4-6 weeks to prevent burnout"
                    ],
                    resources: ["Strong app", "Starting Strength", "GZCLP program"]
                ),
                ProvenStrategy(
                    title: "Nutrition Foundation",
                    description: "You can't out-train a bad diet",
                    tactics: [
                        "Hit protein target daily (0.8-1g per lb bodyweight)",
                        "Prep meals in advance to remove decision fatigue",
                        "Don't drink your calories"
                    ],
                    resources: ["MyFitnessPal", "MacroFactor"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...4, focus: "Learn movements, build habit"),
                ProgressionPhase(name: "Building", weekRange: 5...8, focus: "Progressive overload, nutrition dialed"),
                ProgressionPhase(name: "Momentum", weekRange: 9...12, focus: "Consistent gains, lifestyle integration")
            ]
        )
    }

    // MARK: - Weight Loss Blueprint

    private var weightLossBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .weightLoss,
            defaultSuccessSummary: "Achieve sustainable fat loss through a caloric deficit and movement",
            successOutcomes: [
                DomainOutcome(description: "Lose body fat sustainably", metric: "lbs/week", targetValue: 1),
                DomainOutcome(description: "Maintain muscle mass", metric: "strength maintained %", targetValue: 90),
                DomainOutcome(description: "Build lasting habits", metric: "weeks consistent", targetValue: 12)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Calorie Awareness", beginnerLevel: "No tracking", targetLevel: "Intuitive portion control"),
                PerformanceBenchmark(skill: "Activity Level", beginnerLevel: "Sedentary", targetLevel: "10k+ steps daily"),
                PerformanceBenchmark(skill: "Consistency", beginnerLevel: "All or nothing", targetLevel: "80/20 sustainable approach")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Daily Walking",
                    description: "The most underrated fat loss tool - aim for 8-10k steps",
                    durationMinutes: 45,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.90,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.morning, .afternoon, .evening]
                ),
                CoreActivity(
                    title: "Strength Training",
                    description: "Preserve muscle while losing fat - critical for metabolism",
                    durationMinutes: 45,
                    frequency: .timesPerWeek(3),
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Meal Planning",
                    description: "Plan meals to stay in deficit without feeling deprived",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(2),
                    blockType: .light,
                    impactScore: 0.80,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                ),
                CoreActivity(
                    title: "Weekly Weigh-In & Review",
                    description: "Track trends, not daily fluctuations",
                    durationMinutes: 15,
                    frequency: .once,
                    blockType: .review,
                    impactScore: 0.70,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.morning]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Caloric Deficit",
                    description: "The only thing that matters for fat loss - eat less than you burn",
                    tactics: [
                        "Start with 300-500 calorie deficit (sustainable)",
                        "Prioritize protein to stay full and preserve muscle",
                        "Volume eating - lots of veggies for few calories"
                    ],
                    resources: ["MacroFactor", "Carbon Diet Coach"]
                ),
                ProvenStrategy(
                    title: "NEAT Optimization",
                    description: "Non-exercise activity burns more than workouts for most people",
                    tactics: [
                        "Take stairs, park far, walk during calls",
                        "Stand desk or walking pad",
                        "Post-meal walks improve digestion and blood sugar"
                    ],
                    resources: ["Step counter", "Walking pad"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Awareness", weekRange: 1...2, focus: "Track current intake, establish baseline"),
                ProgressionPhase(name: "Deficit", weekRange: 3...8, focus: "Consistent deficit, building habits"),
                ProgressionPhase(name: "Momentum", weekRange: 9...12, focus: "Visible progress, lifestyle integration")
            ]
        )
    }

    // MARK: - Business Blueprint

    private var businessBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .business,
            defaultSuccessSummary: "Launch and grow a business that generates revenue and serves customers",
            successOutcomes: [
                DomainOutcome(description: "Launch MVP", metric: "weeks to launch", targetValue: 4),
                DomainOutcome(description: "Acquire first customers", metric: "paying customers", targetValue: 10),
                DomainOutcome(description: "Generate revenue", metric: "monthly revenue", targetValue: 1000)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Customer Discovery", beginnerLevel: "Assumptions", targetLevel: "Validated with 20+ conversations"),
                PerformanceBenchmark(skill: "Sales", beginnerLevel: "Uncomfortable", targetLevel: "Can close consistently"),
                PerformanceBenchmark(skill: "Product", beginnerLevel: "Idea", targetLevel: "Working MVP with users")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Customer Conversations",
                    description: "Talk to potential customers - validate problem and solution",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Building/Creating",
                    description: "Actually build the product or service",
                    durationMinutes: 120,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Sales & Outreach",
                    description: "Reach out to potential customers, close deals",
                    durationMinutes: 45,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.afternoon]
                ),
                CoreActivity(
                    title: "Content/Marketing",
                    description: "Share learnings, build audience, attract customers",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .habit,
                    impactScore: 0.70,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Sell Before You Build",
                    description: "Validate demand before investing time in building",
                    tactics: [
                        "Pre-sell the solution with a landing page",
                        "Offer manual/concierge version first",
                        "Get commitment (payment, signup) not just interest"
                    ],
                    resources: ["Stripe", "Carrd", "Gumroad"]
                ),
                ProvenStrategy(
                    title: "Talk to Users Obsessively",
                    description: "The best founders spend 50%+ of time with customers early on",
                    tactics: [
                        "Schedule 3-5 customer calls per week minimum",
                        "Ask about their problems, not your solution",
                        "Listen for emotion - pain = opportunity"
                    ],
                    resources: ["Calendly", "The Mom Test book"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Discovery", weekRange: 1...2, focus: "Customer interviews, problem validation"),
                ProgressionPhase(name: "MVP", weekRange: 3...6, focus: "Build minimum viable product"),
                ProgressionPhase(name: "Launch", weekRange: 7...8, focus: "Get first paying customers"),
                ProgressionPhase(name: "Growth", weekRange: 9...12, focus: "Iterate based on feedback, scale")
            ]
        )
    }

    // MARK: - Income Generation Blueprint

    private var incomeGenerationBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .incomeGeneration,
            defaultSuccessSummary: "Build additional income streams through skills, services, or products",
            successOutcomes: [
                DomainOutcome(description: "Land first client/sale", metric: "weeks to first dollar", targetValue: 3),
                DomainOutcome(description: "Reach income target", metric: "monthly income", targetValue: 2000),
                DomainOutcome(description: "Build recurring revenue", metric: "recurring clients", targetValue: 3)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Skill Monetization", beginnerLevel: "Unsure what to offer", targetLevel: "Clear, valuable offer"),
                PerformanceBenchmark(skill: "Sales", beginnerLevel: "Afraid to charge", targetLevel: "Confident pricing"),
                PerformanceBenchmark(skill: "Delivery", beginnerLevel: "Unproven", targetLevel: "Testimonials and case studies")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Skill Development",
                    description: "Sharpen the skill you'll monetize",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.80,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Outreach & Sales",
                    description: "Cold outreach, warm intros, posting offers",
                    durationMinutes: 45,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.afternoon]
                ),
                CoreActivity(
                    title: "Content Creation",
                    description: "Share expertise to attract inbound leads",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(4),
                    blockType: .habit,
                    impactScore: 0.75,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                ),
                CoreActivity(
                    title: "Client Work",
                    description: "Deliver exceptional results for clients",
                    durationMinutes: 120,
                    frequency: .timesPerWeek(5),
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Productize Your Service",
                    description: "Package your skill into a clear, repeatable offer",
                    tactics: [
                        "Define specific outcome you deliver",
                        "Set fixed price, not hourly",
                        "Create simple process that scales"
                    ],
                    resources: ["Gumroad", "Stripe", "Notion"]
                ),
                ProvenStrategy(
                    title: "100 Outreach Challenge",
                    description: "Volume beats perfection when starting",
                    tactics: [
                        "Send 10 outreach messages per day",
                        "Personalize first line, template the rest",
                        "Follow up 3 times before moving on"
                    ],
                    resources: ["LinkedIn", "Twitter DMs", "Cold email"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Offer Creation", weekRange: 1...2, focus: "Define your offer and pricing"),
                ProgressionPhase(name: "First Clients", weekRange: 3...4, focus: "Land first paying clients"),
                ProgressionPhase(name: "Delivery & Proof", weekRange: 5...8, focus: "Deliver results, get testimonials"),
                ProgressionPhase(name: "Scale", weekRange: 9...12, focus: "Raise prices, systematize")
            ]
        )
    }

    // MARK: - Content Creation Blueprint

    private var contentCreationBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .contentCreation,
            defaultSuccessSummary: "Build an engaged audience and monetize through content",
            successOutcomes: [
                DomainOutcome(description: "Post consistently", metric: "posts/week", targetValue: 5),
                DomainOutcome(description: "Grow audience", metric: "followers", targetValue: 1000),
                DomainOutcome(description: "Achieve engagement", metric: "avg engagement rate %", targetValue: 5)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Content Quality", beginnerLevel: "Inconsistent", targetLevel: "Recognizable style"),
                PerformanceBenchmark(skill: "Posting Cadence", beginnerLevel: "Sporadic", targetLevel: "Daily or near-daily"),
                PerformanceBenchmark(skill: "Audience Connection", beginnerLevel: "Broadcasting", targetLevel: "Genuine conversations")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Content Creation",
                    description: "Create your core content pieces",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Engagement",
                    description: "Reply to comments, engage with others' content",
                    durationMinutes: 30,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.80,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.afternoon, .evening]
                ),
                CoreActivity(
                    title: "Content Research",
                    description: "Study what works, analyze trends",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .light,
                    impactScore: 0.70,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                ),
                CoreActivity(
                    title: "Batch Creation",
                    description: "Create multiple pieces in one session for efficiency",
                    durationMinutes: 120,
                    frequency: .timesPerWeek(2),
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Consistency Over Virality",
                    description: "Daily posting beats occasional viral hits",
                    tactics: [
                        "Post every day for 90 days minimum",
                        "Batch content weekly to stay ahead",
                        "Repurpose across platforms"
                    ],
                    resources: ["Buffer", "Notion content calendar"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...4, focus: "Find your voice, post daily"),
                ProgressionPhase(name: "Growth", weekRange: 5...8, focus: "Optimize what works, engage more"),
                ProgressionPhase(name: "Momentum", weekRange: 9...12, focus: "Build community, explore monetization")
            ]
        )
    }

    // MARK: - Language Learning Blueprint

    private var languageLearningBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .languageLearning,
            defaultSuccessSummary: "Achieve conversational fluency in your target language",
            successOutcomes: [
                DomainOutcome(description: "Daily practice streak", metric: "days consistent", targetValue: 90),
                DomainOutcome(description: "Vocabulary acquired", metric: "words", targetValue: 2000),
                DomainOutcome(description: "Conversation ability", metric: "minutes sustained", targetValue: 15)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Listening", beginnerLevel: "Catch some words", targetLevel: "Follow native content"),
                PerformanceBenchmark(skill: "Speaking", beginnerLevel: "Basic phrases", targetLevel: "Spontaneous conversation"),
                PerformanceBenchmark(skill: "Reading", beginnerLevel: "With dictionary", targetLevel: "News articles fluently")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Speaking Practice",
                    description: "Actually speak - the #1 accelerant for fluency",
                    durationMinutes: 30,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Immersive Listening",
                    description: "Podcasts, videos, music in target language",
                    durationMinutes: 30,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.80,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.morning, .evening]
                ),
                CoreActivity(
                    title: "Vocabulary Review",
                    description: "Spaced repetition with flashcards",
                    durationMinutes: 15,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.75,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Grammar Study",
                    description: "Structured learning of grammar patterns",
                    durationMinutes: 20,
                    frequency: .timesPerWeek(4),
                    blockType: .light,
                    impactScore: 0.65,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Comprehensible Input",
                    description: "Consume content slightly above your level",
                    tactics: [
                        "Watch shows with target language subtitles",
                        "Listen to podcasts for learners",
                        "Read graded readers, then native content"
                    ],
                    resources: ["Dreaming Spanish", "Language Transfer", "LingQ"]
                ),
                ProvenStrategy(
                    title: "Speaking from Day 1",
                    description: "Don't wait until you're 'ready' - speak immediately",
                    tactics: [
                        "Find language exchange partners",
                        "Book tutoring sessions (cheap on iTalki)",
                        "Talk to yourself in the language"
                    ],
                    resources: ["iTalki", "HelloTalk", "Tandem"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...4, focus: "Core vocabulary and sounds"),
                ProgressionPhase(name: "Building", weekRange: 5...12, focus: "Grammar patterns, first conversations"),
                ProgressionPhase(name: "Immersion", weekRange: 13...24, focus: "Native content, extended conversations")
            ]
        )
    }

    // MARK: - Academic Success Blueprint

    private var academicSuccessBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .academicSuccess,
            defaultSuccessSummary: "Achieve academic goals through effective study strategies and consistency",
            successOutcomes: [
                DomainOutcome(description: "Study consistently", metric: "hours/week", targetValue: 20),
                DomainOutcome(description: "Improve grades", metric: "GPA increase", targetValue: 0.5),
                DomainOutcome(description: "Master material", metric: "retention %", targetValue: 85)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Study Efficiency", beginnerLevel: "Passive rereading", targetLevel: "Active recall mastery"),
                PerformanceBenchmark(skill: "Time Management", beginnerLevel: "Cramming", targetLevel: "Spaced, consistent review"),
                PerformanceBenchmark(skill: "Focus", beginnerLevel: "Easily distracted", targetLevel: "Deep work sessions")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Active Recall Practice",
                    description: "Test yourself on material - most effective study method",
                    durationMinutes: 45,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.95,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Spaced Repetition Review",
                    description: "Review material at optimal intervals",
                    durationMinutes: 20,
                    frequency: .daily,
                    blockType: .habit,
                    impactScore: 0.85,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Deep Study Session",
                    description: "Focused learning of new material",
                    durationMinutes: 50,
                    frequency: .timesPerWeek(5),
                    blockType: .focus,
                    impactScore: 0.80,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Practice Problems",
                    description: "Apply knowledge through problems and exercises",
                    durationMinutes: 45,
                    frequency: .timesPerWeek(4),
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.afternoon]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Active Recall + Spaced Repetition",
                    description: "The scientifically proven combo for long-term retention",
                    tactics: [
                        "Close the book and test yourself",
                        "Use Anki for spaced repetition",
                        "Explain concepts without notes"
                    ],
                    resources: ["Anki", "RemNote", "Quizlet"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Setup", weekRange: 1...2, focus: "Build study system and schedule"),
                ProgressionPhase(name: "Consistency", weekRange: 3...8, focus: "Daily practice, habit formation"),
                ProgressionPhase(name: "Mastery", weekRange: 9...12, focus: "Deep understanding, exam prep")
            ]
        )
    }

    // MARK: - Career Transition Blueprint

    private var careerTransitionBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .careerTransition,
            defaultSuccessSummary: "Successfully transition into a new career field",
            successOutcomes: [
                DomainOutcome(description: "Acquire new skills", metric: "skills demonstrated", targetValue: 3),
                DomainOutcome(description: "Build network in new field", metric: "connections", targetValue: 20),
                DomainOutcome(description: "Land new role", metric: "interviews", targetValue: 5)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Domain Knowledge", beginnerLevel: "Outsider", targetLevel: "Conversant in field"),
                PerformanceBenchmark(skill: "Transferable Skills", beginnerLevel: "Hidden", targetLevel: "Clearly articulated"),
                PerformanceBenchmark(skill: "Network", beginnerLevel: "None in field", targetLevel: "Multiple warm connections")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Skill Building",
                    description: "Learn the must-have skills for new field",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 4,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Informational Interviews",
                    description: "Talk to people in target role to understand path",
                    durationMinutes: 45,
                    frequency: .timesPerWeek(3),
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.afternoon]
                ),
                CoreActivity(
                    title: "Portfolio/Proof Building",
                    description: "Create tangible evidence of new skills",
                    durationMinutes: 60,
                    frequency: .timesPerWeek(4),
                    blockType: .focus,
                    impactScore: 0.85,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning, .afternoon]
                ),
                CoreActivity(
                    title: "Story Crafting",
                    description: "Develop compelling narrative for why you're transitioning",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(2),
                    blockType: .light,
                    impactScore: 0.80,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Bridge the Gap",
                    description: "Connect your past experience to new field",
                    tactics: [
                        "Identify transferable skills",
                        "Frame experience in terms new field values",
                        "Get adjacent experience first if needed"
                    ],
                    resources: ["LinkedIn Learning", "Career counseling"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Research", weekRange: 1...2, focus: "Understand new field, map the path"),
                ProgressionPhase(name: "Skill Building", weekRange: 3...8, focus: "Acquire must-have skills"),
                ProgressionPhase(name: "Positioning", weekRange: 9...12, focus: "Network, apply, interview")
            ]
        )
    }

    // MARK: - General Blueprint

    private var generalBlueprint: DomainBlueprint {
        DomainBlueprint(
            domain: .general,
            defaultSuccessSummary: "Make meaningful progress toward your goal through consistent action",
            successOutcomes: [
                DomainOutcome(description: "Consistent daily action", metric: "days active", targetValue: 60),
                DomainOutcome(description: "Measurable progress", metric: "milestones hit", targetValue: 4),
                DomainOutcome(description: "Habit formation", metric: "weeks consistent", targetValue: 8)
            ],
            performanceBenchmarks: [
                PerformanceBenchmark(skill: "Consistency", beginnerLevel: "Sporadic", targetLevel: "Daily practice"),
                PerformanceBenchmark(skill: "Focus", beginnerLevel: "Scattered", targetLevel: "Clear priorities"),
                PerformanceBenchmark(skill: "Progress", beginnerLevel: "None", targetLevel: "Visible improvement")
            ],
            highLeverageActivities: [
                CoreActivity(
                    title: "Core Practice",
                    description: "The main activity that moves you toward your goal",
                    durationMinutes: 60,
                    frequency: .daily,
                    blockType: .focus,
                    impactScore: 0.90,
                    difficultyLevel: 3,
                    preferredTimeOfDay: [.morning]
                ),
                CoreActivity(
                    title: "Learning & Research",
                    description: "Study best practices and learn from others",
                    durationMinutes: 30,
                    frequency: .timesPerWeek(3),
                    blockType: .light,
                    impactScore: 0.70,
                    difficultyLevel: 2,
                    preferredTimeOfDay: [.evening]
                ),
                CoreActivity(
                    title: "Weekly Review",
                    description: "Reflect on progress and adjust approach",
                    durationMinutes: 30,
                    frequency: .once,
                    blockType: .review,
                    impactScore: 0.75,
                    difficultyLevel: 1,
                    preferredTimeOfDay: [.evening]
                )
            ],
            provenStrategies: [
                ProvenStrategy(
                    title: "Consistency Compounds",
                    description: "Small daily actions beat occasional big efforts",
                    tactics: [
                        "Show up every day, even if just for 15 minutes",
                        "Track your streak - don't break the chain",
                        "Focus on systems, not just goals"
                    ],
                    resources: ["Habit tracker", "Calendar blocking"]
                )
            ],
            progressionPhases: [
                ProgressionPhase(name: "Foundation", weekRange: 1...4, focus: "Build the habit, establish routine"),
                ProgressionPhase(name: "Building", weekRange: 5...8, focus: "Increase intensity, see progress"),
                ProgressionPhase(name: "Momentum", weekRange: 9...12, focus: "Compound gains, evaluate next steps")
            ]
        )
    }
}

// MARK: - Supporting Types

struct DomainBlueprint {
    let domain: GoalDomainType
    let defaultSuccessSummary: String
    let successOutcomes: [DomainOutcome]
    let performanceBenchmarks: [PerformanceBenchmark]
    let highLeverageActivities: [CoreActivity]
    let provenStrategies: [ProvenStrategy]
    let progressionPhases: [ProgressionPhase]

    func getThemeForProgress(_ ratio: Double) -> (title: String, focus: String) {
        for phase in progressionPhases {
            let phaseStart = Double(phase.weekRange.lowerBound) / Double(progressionPhases.last?.weekRange.upperBound ?? 12)
            let phaseEnd = Double(phase.weekRange.upperBound) / Double(progressionPhases.last?.weekRange.upperBound ?? 12)
            if ratio >= phaseStart && ratio <= phaseEnd {
                return (phase.name, phase.focus)
            }
        }
        return (progressionPhases.last?.name ?? "Execution", progressionPhases.last?.focus ?? "Keep going")
    }
}

struct DomainOutcome {
    let description: String
    let metric: String
    let targetValue: Double
}

struct ProgressionPhase {
    let name: String
    let weekRange: ClosedRange<Int>
    let focus: String
}
