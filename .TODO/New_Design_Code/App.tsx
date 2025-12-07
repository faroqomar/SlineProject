import React, { useState } from "react";
import {
  Search,
  Filter,
  TrendingUp,
  Clock,
  Users,
  Heart,
  Plus,
  Home,
  MessageCircle,
  User,
  X,
  ArrowUpRight,
  FileText,
  Calendar,
  ChevronLeft,
  Share,
  MoreHorizontal,
  MapPin,
  ShieldCheck,
  Briefcase,
  CheckCircle2,
  GraduationCap,
  Sparkles,
  Zap,
  ChevronRight,
  Layers,
  Repeat,
  Send,
  Paperclip,
  Smile,
  Phone,
  Video,
  DollarSign,
  Download,
  ExternalLink,
  MessageSquare,
  AlertCircle,
  Upload,
  CreditCard,
  ArrowDownLeft,
  Wallet,
  History,
  Bell,
  Check,
  Star,
  Image,
  Grid,
  ArrowUpDown
} from "lucide-react";
import { 
  Task, 
  Message, 
  NavView, 
  AuthView, 
  CategoryId, 
  TaskFormState,
  ProfileMenuItem,
  PopularCategory,
  ProfileStat,
  Category,
  ServiceTier,
  ChatMessage,
  Proposal,
  ProposalFormState,
  Order,
  OrderStatus,
  WalletData,
  Transaction,
  Notification,
  FilterState,
  FreelancerProfile
} from "./types";

export default function App() {
  const [likedTasks, setLikedTasks] = useState<Set<number>>(
    new Set([1]),
  );
  const [activeNav, setActiveNav] = useState<NavView>("home");
  const [activeCategory, setActiveCategory] = useState<CategoryId>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [selectedChat, setSelectedChat] = useState<Message | null>(null);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const [selectedUserProfile, setSelectedUserProfile] = useState<FreelancerProfile | null>(null);
  
  // Orders Dashboard State
  const [activeOrderTab, setActiveOrderTab] = useState<OrderStatus>("Active");

  // States for Service Packages features
  const [selectedPackageTier, setSelectedPackageTier] = useState<ServiceTier>("Basic");
  const [activePackageTab, setActivePackageTab] = useState<ServiceTier>("Basic");

  // Chat Offer States
  const [showOfferModal, setShowOfferModal] = useState(false);
  const [offerForm, setOfferForm] = useState({
    title: '',
    description: '',
    price: '',
    deliveryTime: '3'
  });

  // Proposal States
  const [showProposalModal, setShowProposalModal] = useState(false);
  const [proposalForm, setProposalForm] = useState<ProposalFormState>({
    bidAmount: '',
    deliveryTime: '3 Days',
    coverLetter: ''
  });
  
  // Notification & Filter States
  const [showNotifications, setShowNotifications] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState<FilterState>({
    minBudget: '',
    maxBudget: '',
    deliveryTime: [],
    sellerLevel: [],
    sortBy: 'Relevance'
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [recentSearches, setRecentSearches] = useState([
    "UI/UX Design",
    "React Developer",
    "Logo Design",
    "Content Writing",
  ]);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [authScreen, setAuthScreen] = useState<AuthView>("login");
  const [isDarkMode, setIsDarkMode] = useState(true);
  const [showCreateTask, setShowCreateTask] = useState(false);
  const [createStep, setCreateStep] = useState(1);
  const [taskForm, setTaskForm] = useState<TaskFormState>({
    title: "",
    description: "",
    category: "design",
    budget: "",
    type: "Tender",
    tags: "",
    deadline: "7",
    experienceLevel: "Intermediate",
    packages: {
      Basic: { price: "", deliveryTime: "3", description: "", revisions: "1" },
      Standard: { price: "", deliveryTime: "7", description: "", revisions: "2" },
      Premium: { price: "", deliveryTime: "14", description: "", revisions: "Unlimited" }
    }
  });

  const toggleLike = (taskId: number) => {
    const newLiked = new Set(likedTasks);
    if (newLiked.has(taskId)) {
      newLiked.delete(taskId);
    } else {
      newLiked.add(taskId);
    }
    setLikedTasks(newLiked);
  };

  const handleCloseCreateTask = () => {
    setShowCreateTask(false);
    setTimeout(() => setCreateStep(1), 300);
  };

  const handleSubmitProposal = () => {
    console.log("Submitting proposal:", proposalForm);
    setShowProposalModal(false);
    // Reset form or show success toast
  };

  const handleSendOffer = () => {
    if (!selectedChat) return;

    const newOfferMsg: ChatMessage = {
      id: Date.now(),
      text: "",
      sender: 'me',
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      type: 'offer',
      offer: {
        title: offerForm.title,
        description: offerForm.description,
        price: `$${offerForm.price}`,
        deliveryTime: `${offerForm.deliveryTime} Days`,
        status: 'pending'
      }
    };

    // Update the selected chat's history locally (In a real app, this would be an API call)
    const updatedChat = {
      ...selectedChat,
      history: [...(selectedChat.history || []), newOfferMsg]
    };
    
    setSelectedChat(updatedChat);
    setShowOfferModal(false);
    setOfferForm({ title: '', description: '', price: '', deliveryTime: '3' });
  };
  
  const toggleFilter = (type: 'deliveryTime' | 'sellerLevel', value: string) => {
    const current = filters[type];
    const newValues = current.includes(value) 
      ? current.filter(i => i !== value)
      : [...current, value];
    setFilters({...filters, [type]: newValues});
  };

  const popularCategories: PopularCategory[] = [
    { icon: "🎨", name: "Design", color: "#f49d9d" },
    { icon: "💻", name: "Development", color: "#93ccce" },
    { icon: "✍️", name: "Writing", color: "#f7d69c" },
    { icon: "📱", name: "Mobile", color: "#f3bb19" },
    { icon: "🎯", name: "Marketing", color: "#9dbabb" },
    { icon: "🎬", name: "Video", color: "#146068" },
  ];
  
  const notifications: Notification[] = [
    { id: 1, type: 'order', title: 'Order Update', message: 'Nexus Corp marked your order as Completed.', time: '2m ago', isRead: false, group: 'Today' },
    { id: 2, type: 'proposal', title: 'New Proposal', message: 'David Chen applied to your Logo Design job.', time: '1h ago', isRead: false, group: 'Today' },
    { id: 3, type: 'system', title: 'System Alert', message: 'Your password was changed successfully.', time: '3h ago', isRead: true, group: 'Today' },
    { id: 4, type: 'payment', title: 'Payment Received', message: 'You received $250.00 from TravelLife.', time: 'Yesterday', isRead: true, group: 'Yesterday' },
    { id: 5, type: 'proposal', title: 'Proposal Accepted', message: 'Your proposal for React Dashboard was accepted!', time: 'Yesterday', isRead: true, group: 'Yesterday' },
  ];

  const mockFreelancerProfile: FreelancerProfile = {
    id: 101,
    name: "David Chen",
    initials: "DC",
    title: "Senior Brand Designer",
    bio: "Award-winning designer with 7+ years of experience crafting visual identities for tech startups. I specialize in minimalist logos, comprehensive brand guidelines, and UI design. My work has been featured in major design blogs.",
    location: "Toronto, Canada",
    rating: "4.9",
    jobsCompleted: 142,
    hourlyRate: "$65/hr",
    jobSuccess: "98%",
    skills: ["Logo Design", "Branding", "Adobe Illustrator", "Figma", "Typography", "Visual Identity"],
    verified: true,
    online: true,
    portfolio: [
      { id: 1, image: "#146068", title: "Apex Tech Rebrand", category: "Branding" },
      { id: 2, image: "#f3bb19", title: "Solaris Logo", category: "Logo Design" },
      { id: 3, image: "#f49d9d", title: "EcoLife App UI", category: "UI/UX" },
      { id: 4, image: "#93ccce", title: "Modern FinTech Identity", category: "Branding" }
    ],
    reviews: [
      { id: 1, clientName: "Sarah J.", clientInitials: "SJ", rating: 5, comment: "David is incredibly talented! He understood our vision perfectly and delivered a stunning logo.", date: "2 weeks ago" },
      { id: 2, clientName: "TechFlow Inc", clientInitials: "TF", rating: 5, comment: "Professional, fast, and high quality. Highly recommended for any branding work.", date: "1 month ago" }
    ]
  };

  const orders: Order[] = [
    {
      id: 101,
      title: "Corporate Brand Identity Pack",
      client: { name: "Nexus Corp", initials: "NC" },
      price: "$1,200",
      status: "Active",
      type: "Tender",
      dueDate: "2023-11-20",
      timeLeft: "2d 14h 32m"
    },
    {
      id: 102,
      title: "Mobile App UI Audit",
      client: { name: "StartUp Inc", initials: "SI" },
      price: "$350",
      status: "Revision",
      type: "Booking",
      dueDate: "2023-11-15"
    },
    {
      id: 103,
      title: "React Dashboard Components",
      client: { name: "DevStudio", initials: "DS" },
      price: "$800",
      status: "Completed",
      type: "Booking",
      dueDate: "2023-11-10"
    },
    {
      id: 104,
      title: "Blog Post Series (5x)",
      client: { name: "TravelLife", initials: "TL" },
      price: "$250",
      status: "Cancelled",
      type: "Tender",
      dueDate: "2023-11-01"
    }
  ];

  const walletData: WalletData = {
    totalBalance: "12,540.00",
    availableBalance: "11,690.00",
    escrowBalance: "850.00",
    currency: "USD",
    cardLast4: "4242",
    transactions: [
      { id: 1, type: "payment", description: "Payment Released: Brand Identity", amount: "1,200.00", date: "Today, 2:30 PM", status: "completed", isPositive: true },
      { id: 2, type: "fee", description: "Service Fee (5%)", amount: "60.00", date: "Today, 2:30 PM", status: "completed", isPositive: false },
      { id: 3, type: "withdrawal", description: "Withdrawal to Bank Account", amount: "2,500.00", date: "Yesterday", status: "completed", isPositive: false },
      { id: 4, type: "escrow", description: "Escrow Deposit: UI Audit", amount: "350.00", date: "Nov 12, 2023", status: "pending", isPositive: true },
      { id: 5, type: "payment", description: "Payment Released: Blog Series", amount: "250.00", date: "Nov 10, 2023", status: "completed", isPositive: true },
    ]
  };

  const messages: Message[] = [
    {
      id: 1,
      name: "Sarah Miller",
      initials: "SM",
      lastMessage:
        "Great! I can start working on the React project tomorrow.",
      time: "2m ago",
      unread: 3,
      online: true,
      verified: true,
      history: [
        { id: 1, text: "Hi Sarah, I saw your portfolio and I'm interested in working with you.", sender: 'me', time: '10:30 AM', type: 'text' },
        { id: 2, text: "Hello! Thanks for reaching out. I'd love to hear more about the project.", sender: 'them', time: '10:32 AM', type: 'text' },
        { id: 3, text: "I need a React expert to help optimize our dashboard performance.", sender: 'me', time: '10:35 AM', type: 'text' },
        { id: 4, text: "That's right up my alley. I can do a full audit and implementation.", sender: 'them', time: '10:40 AM', type: 'text' },
        { 
          id: 5, 
          text: "", 
          sender: 'them', 
          time: '10:42 AM', 
          type: 'offer',
          offer: {
            title: "Performance Optimization Package",
            description: "Full codebase audit, memoization implementation, and load time reduction.",
            price: "$450",
            status: 'pending'
          }
        },
        { id: 6, text: "Great! I can start working on the React project tomorrow.", sender: 'them', time: '10:45 AM', type: 'text' }
      ]
    },
    {
      id: 2,
      name: "John Doe",
      initials: "JD",
      lastMessage:
        "Thanks for accepting my offer! When can we discuss the details?",
      time: "15m ago",
      unread: 1,
      online: true,
      verified: true,
    },
    {
      id: 3,
      name: "Mike Johnson",
      initials: "MJ",
      lastMessage:
        "I have sent you the final draft. Please review it.",
      time: "1h ago",
      unread: 0,
      online: false,
      verified: false,
    },
    {
      id: 4,
      name: "Emma Wilson",
      initials: "EW",
      lastMessage:
        "The designs look amazing! Just a few minor tweaks needed.",
      time: "3h ago",
      unread: 0,
      online: true,
      verified: true,
    },
    {
      id: 5,
      name: "Alex Chen",
      initials: "AC",
      lastMessage:
        "Can you share your portfolio? I would love to see more of your work.",
      time: "5h ago",
      unread: 0,
      online: false,
      verified: false,
    },
    {
      id: 6,
      name: "Lisa Anderson",
      initials: "LA",
      lastMessage:
        "Payment has been sent. Thank you for the excellent work!",
      time: "1d ago",
      unread: 0,
      online: false,
      verified: true,
    },
  ];

  const profileStats: ProfileStat[] = [
    { label: "Projects", value: "47", color: "#146068" },
    { label: "Rating", value: "4.9", color: "#f3bb19" },
    { label: "Earned", value: "$12.5k", color: "#93ccce" },
  ];

  const profileMenuItems: ProfileMenuItem[] = [
    {
      icon: "User",
      label: "Edit Profile",
      description: "Update your personal information",
      color: "#146068",
      badge: null,
    },
    {
      icon: "Heart",
      label: "Saved Projects",
      description: "View your favorite projects",
      color: "#f49d9d",
      badge: "12",
    },
    {
      icon: "Clock",
      label: "Work History",
      description: "See your completed work",
      color: "#93ccce",
      badge: null,
    },
    {
      icon: "⚙️",
      label: "Settings",
      description: "Manage your preferences",
      color: "#9dbabb",
      badge: null,
    },
    {
      icon: "📊",
      label: "Analytics",
      description: "View your performance",
      color: "#f7d69c",
      badge: "New",
    },
    {
      icon: "💰",
      label: "Payments",
      description: "Manage your earnings",
      color: "#f3bb19",
      badge: null,
    },
  ];

  const categories: Category[] = [
    { id: "all", label: "✨ All" },
    { id: "design", label: "🎨 Design" },
    { id: "dev", label: "💻 Dev" },
    { id: "writing", label: "✍️ Writing" },
    { id: "mobile", label: "📱 Mobile" },
    { id: "marketing", label: "🎯 Marketing" },
  ];

  const tasks: Task[] = [
    {
      id: 1,
      type: "Tender",
      isHot: true,
      bgColor: "#f49d9d",
      author: {
        name: "John Doe",
        initials: "JD",
        verified: true,
        time: "2 hours ago",
      },
      title: "Modern Logo Design for AI Startup",
      description:
        "Looking for a creative designer to create a stunning, modern logo for our AI-powered SaaS platform with full brand guidelines. The ideal candidate should have experience in tech branding and be able to deliver vector files.",
      tags: ["Design", "Branding", "Logo", "AI"],
      timeLeft: "5d left",
      offers: 23,
      budget: "$750",
      proposals: [
        {
          id: 101,
          freelancer: {
            name: "David Chen",
            initials: "DC",
            rating: "4.8",
            verified: true,
            location: "Canada",
            online: true
          },
          bidAmount: "$700",
          deliveryTime: "4 Days",
          coverLetter: "Hi, I have 5 years of experience in logo design and branding for tech startups. I utilize Adobe Illustrator and can provide vector files. I've worked with AI companies before and understand the aesthetic you're looking for.",
          attachments: ["portfolio_v1.pdf", "concept_sketch.jpg"],
          submittedAt: "1h ago"
        },
        {
          id: 102,
          freelancer: {
            name: "Maria Garcia",
            initials: "MG",
            rating: "4.9",
            verified: true,
            location: "Spain",
            online: false
          },
          bidAmount: "$750",
          deliveryTime: "5 Days",
          coverLetter: "I specialize in minimalist and modern branding. My process involves 3 initial concepts and unlimited revisions until you are satisfied. Check my attached portfolio.",
          attachments: ["branding_kit_sample.pdf"],
          submittedAt: "3h ago"
        }
      ]
    },
    {
      id: 2,
      type: "Booking",
      isHot: false,
      bgColor: "#93ccce",
      author: {
        name: "Sarah Miller",
        initials: "SM",
        verified: true,
        time: "5 hours ago",
      },
      title: "React + Node.js Expert Consultation",
      description:
        "Need expert guidance on scalable architecture for a React + Node.js SaaS application. 1-hour video session to review current codebase and suggest improvements for performance.",
      tags: ["Development", "React", "Node.js", "Architecture"],
      timeLeft: "Available",
      offers: null,
      budget: "$200",
      packages: [
        {
          tier: "Basic",
          price: "$200",
          deliveryTime: "2 Days",
          description: "1-hour video consultation + brief summary report. Perfect for quick questions.",
          revisions: "0"
        },
        {
          tier: "Standard",
          price: "$450",
          deliveryTime: "5 Days",
          description: "1-hour consultation + code review (up to 500 lines) + detailed architectural roadmap.",
          revisions: "1"
        },
        {
          tier: "Premium",
          price: "$900",
          deliveryTime: "10 Days",
          description: "Everything in Standard + 5 hours of dedicated implementation support and follow-up.",
          revisions: "3"
        }
      ]
    },
    {
      id: 3,
      type: "Tender",
      isHot: false,
      bgColor: "#f7d69c",
      author: {
        name: "Mike Johnson",
        initials: "MJ",
        verified: false,
        time: "1 day ago",
      },
      title: "SEO Travel Blog Content Writing",
      description:
        "Need 10 SEO-optimized travel articles (1000 words each) about European destinations with engaging storytelling. Keywords will be provided. Must be native English speaker.",
      tags: ["Writing", "SEO", "Travel", "Content"],
      timeLeft: "14d left",
      offers: 15,
      budget: "$950",
    },
  ];

  const renderIcon = (iconName: string, className: string) => {
    const iconMap: { [key: string]: React.ReactNode } = {
      User: <User className={className} strokeWidth={2} />,
      Heart: <Heart className={className} strokeWidth={2} />,
      Clock: <Clock className={className} strokeWidth={2} />,
    };

    return (
      iconMap[iconName] || (
        <span className="text-[20px]">{iconName}</span>
      )
    );
  };

  // Theme system
  const theme = {
    // Main backgrounds
    phoneBg: isDarkMode ? "#0c0c0c" : "#f4f3f1",
    dynamicIsland: isDarkMode ? "#0c0c0c" : "#f4f3f1",

    // Status bar
    statusBarText: isDarkMode ? "#f4f3f1" : "#0c0c0c",

    // Auth screens
    authGradient: isDarkMode
      ? "from-[#146068]/5 to-[#0c0c0c]"
      : "from-[#93ccce]/15 to-[#f4f3f1]",
    authText: isDarkMode ? "#f4f3f1" : "#0c0c0c",
    authTextSecondary: isDarkMode ? "#9dbabb" : "#a9a8a7",
    authInputBg: isDarkMode
      ? "bg-[#f4f3f1]/10"
      : "bg-[#ffffff]",
    authInputBorder: isDarkMode
      ? "border-[#93ccce]/20"
      : "border-[#146068]/20",
    authInputText: isDarkMode ? "#f4f3f1" : "#0c0c0c",

    // Header
    headerBg: isDarkMode
      ? "bg-[#146068]/20"
      : "bg-[#93ccce]/15",
    headerBorder: isDarkMode
      ? "border-[#93ccce]/20"
      : "border-[#146068]/20",

    // Text
    text: isDarkMode ? "#f4f3f1" : "#0c0c0c",
    textSecondary: isDarkMode ? "#9dbabb" : "#a9a8a7",
    textTertiary: isDarkMode ? "#a9a8a7" : "#6b6b6b",

    // Cards
    cardBg: isDarkMode ? "bg-[#f4f3f1]/8" : "bg-[#ffffff]",
    cardBorder: isDarkMode
      ? "border-[#93ccce]/10"
      : "border-[#146068]/15",
    cardBorderHover: isDarkMode
      ? "border-[#146068]/40"
      : "border-[#146068]/50",

    // Input
    inputBg: isDarkMode ? "bg-[#f4f3f1]/10" : "bg-[#ffffff]",
    inputBorder: isDarkMode
      ? "border-[#93ccce]/20"
      : "border-[#146068]/20",
    inputFocusBg: isDarkMode
      ? "focus:bg-[#f4f3f1]/15"
      : "focus:bg-[#ffffff]",

    tagBg: isDarkMode ? "bg-[#f4f3f1]/10" : "bg-[#ffffff]",
    tagBorder: isDarkMode ? "border-[#93ccce]/10" : "border-[#146068]/15",

    // Content area
    contentGradient: isDarkMode
      ? "from-transparent to-[#0c0c0c]/70"
      : "from-transparent to-[#f4f3f1]",
    scrollbarColor: isDarkMode
      ? "#146068 transparent"
      : "#93ccce transparent",

    // Bottom navigation - REMOVED here, handled inline for liquid effect
    bottomNavInactive: isDarkMode ? "#9dbabb" : "#a9a8a7",
    bottomNavBg: isDarkMode ? "bg-[#146068]/20" : "bg-[#93ccce]/15",
    bottomNavBorder: isDarkMode ? "border-[#93ccce]/20" : "border-[#146068]/20",

    // Special elements
    dividerBg: isDarkMode
      ? "bg-[#93ccce]/20"
      : "bg-[#146068]/15",
    hotBadgeBg: "bg-[#f3bb19]/20",
    hotBadgeBorder: "border-[#f3bb19]/30",

    // Task gradient overlay
    taskGradient: isDarkMode
      ? "from-[#0c0c0c]/60"
      : "from-[#0c0c0c]/40",
  };

  const getSelectedPackage = () => {
    if (!selectedTask || !selectedTask.packages) return null;
    return selectedTask.packages.find(p => p.tier === selectedPackageTier);
  };
  
  const currentPackage = getSelectedPackage();
  const displayBudget = currentPackage ? currentPackage.price : selectedTask?.budget;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#146068] via-[#93ccce] to-[#f7d69c] flex items-center justify-center p-5">
      {/* Phone Mockup - Removed border/notch elements per request */}
      <div
        className="w-full max-w-[390px] h-[844px] rounded-[50px] shadow-2xl relative overflow-hidden flex flex-col transition-colors duration-500"
        style={{
          backgroundColor: theme.phoneBg,
          boxShadow: isDarkMode 
            ? "0 0 0 1px rgba(255,255,255,0.1), 0 30px 60px -10px rgba(0,0,0,0.5)" 
            : "0 0 0 1px rgba(0,0,0,0.05), 0 30px 60px -10px rgba(0,0,0,0.2)"
        }}
      >
        {/* Global Noise Texture */}
        <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />

        {!isLoggedIn ? (
          // ... Auth Screens (No changes) ...
          <div
            className={`flex-1 flex flex-col items-center justify-center px-8 py-12 bg-gradient-to-b ${theme.authGradient} transition-all duration-500 animate-fade-in relative z-10`}
          >
             {/* Login/Signup content same as before, omitted for brevity */}
            {authScreen === "login" ? (
              // Login Screen
              <>
                <div className="w-full mb-8">
                  <div className="w-20 h-20 bg-[#146068] rounded-[20px] mx-auto mb-6 flex items-center justify-center shadow-2xl animate-spring">
                    <span className="text-[36px] font-extrabold text-[#f4f3f1]">
                      S
                    </span>
                  </div>
                  <h1
                    className="text-[32px] font-extrabold text-center mb-2 tracking-tight leading-none transition-colors duration-500"
                    style={{ color: theme.authText }}
                  >
                    Welcome Back
                  </h1>
                  <p
                    className="text-[14px] text-center transition-colors duration-500"
                    style={{ color: theme.authTextSecondary }}
                  >
                    Sign in to continue to SLine
                  </p>
                </div>

                <div className="w-full space-y-4 mb-6">
                  <div>
                    <label
                      className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
                      style={{ color: theme.authText }}
                    >
                      Email
                    </label>
                    <input
                      type="email"
                      placeholder="your@email.com"
                      className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                      style={{ color: theme.authInputText }}
                    />
                  </div>
                  <div>
                    <label
                      className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
                      style={{ color: theme.authText }}
                    >
                      Password
                    </label>
                    <input
                      type="password"
                      placeholder="Enter your password"
                      className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                      style={{ color: theme.authInputText }}
                    />
                  </div>
                  <button className="text-[13px] font-semibold text-[#146068] hover:text-[#93ccce] transition-colors text-right w-full">
                    Forgot Password?
                  </button>
                </div>

                <button
                  onClick={() => setIsLoggedIn(true)}
                  className="w-full h-[54px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:bg-[#146068]/90 transition-all duration-300 hover:scale-[1.02] active:scale-95 shadow-xl mb-4"
                >
                  Sign In
                </button>

                <div className="flex items-center gap-2 w-full mb-4">
                  <div
                    className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
                  ></div>
                  <span
                    className="text-[12px] font-semibold transition-colors duration-500"
                    style={{ color: theme.authTextSecondary }}
                  >
                    OR
                  </span>
                  <div
                    className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
                  ></div>
                </div>

                <div className="flex gap-3 w-full mb-6">
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">🔍</span>
                  </button>
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">📘</span>
                  </button>
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">🍎</span>
                  </button>
                </div>

                <p
                  className="text-[13px] text-center transition-colors duration-500"
                  style={{ color: theme.authTextSecondary }}
                >
                  Don't have an account?{" "}
                  <button
                    onClick={() => setAuthScreen("signup")}
                    className="text-[#146068] font-bold hover:text-[#93ccce] transition-colors"
                  >
                    Sign In
                  </button>
                </p>
              </>
            ) : (
              // Signup Screen
              <>
                 <div className="w-full mb-8">
                  <div className="w-20 h-20 bg-[#146068] rounded-[20px] mx-auto mb-6 flex items-center justify-center shadow-2xl animate-spring">
                    <span className="text-[36px] font-extrabold text-[#f4f3f1]">
                      S
                    </span>
                  </div>
                  <h1
                    className="text-[32px] font-extrabold text-center mb-2 tracking-tight leading-none transition-colors duration-500"
                    style={{ color: theme.authText }}
                  >
                    Create Account
                  </h1>
                  <p
                    className="text-[14px] text-center transition-colors duration-500"
                    style={{ color: theme.authTextSecondary }}
                  >
                    Join SLine today
                  </p>
                </div>
                 <div className="w-full space-y-4 mb-6">
                  <div>
                    <label
                      className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
                      style={{ color: theme.authText }}
                    >
                      Full Name
                    </label>
                    <input
                      type="text"
                      placeholder="John Doe"
                      className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                      style={{ color: theme.authInputText }}
                    />
                  </div>
                  <div>
                    <label
                      className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
                      style={{ color: theme.authText }}
                    >
                      Email
                    </label>
                    <input
                      type="email"
                      placeholder="your@email.com"
                      className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                      style={{ color: theme.authInputText }}
                    />
                  </div>
                  <div>
                    <label
                      className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
                      style={{ color: theme.authText }}
                    >
                      Password
                    </label>
                    <input
                      type="password"
                      placeholder="Create a password"
                      className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                      style={{ color: theme.authInputText }}
                    />
                  </div>
                </div>

                <button
                  onClick={() => setIsLoggedIn(true)}
                  className="w-full h-[54px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:bg-[#146068]/90 transition-all duration-300 hover:scale-[1.02] active:scale-95 shadow-xl mb-4"
                >
                  Create Account
                </button>
                <div className="flex items-center gap-2 w-full mb-4">
                  <div
                    className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
                  ></div>
                  <span
                    className="text-[12px] font-semibold transition-colors duration-500"
                    style={{ color: theme.authTextSecondary }}
                  >
                    OR
                  </span>
                  <div
                    className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
                  ></div>
                </div>

                <div className="flex gap-3 w-full mb-6">
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">🔍</span>
                  </button>
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">📘</span>
                  </button>
                  <button
                    className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
                  >
                    <span className="text-[20px]">🍎</span>
                  </button>
                </div>

                <p
                  className="text-[13px] text-center transition-colors duration-500"
                  style={{ color: theme.authTextSecondary }}
                >
                  Already have an account?{" "}
                  <button
                    onClick={() => setAuthScreen("login")}
                    className="text-[#146068] font-bold hover:text-[#93ccce] transition-colors"
                  >
                    Sign In
                  </button>
                </p>
              </>
            )}
          </div>
        ) : (
          <>
            {/* Main App Content */}
            <div className="flex-1 flex flex-col overflow-hidden relative animate-fade-in z-10">
               <div
                className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}
              >
                  {/* Navigation Header Logic */}
                  {activeNav === "home" ? (
                  <>
                    <div className="flex justify-between items-center mb-6">
                        <div className="flex items-center gap-3">
                            <div className="w-[52px] h-[52px] rounded-[18px] bg-[#f3bb19] border-2 border-[#f4f3f1]/20 overflow-hidden relative shadow-lg">
                                <img 
                                    src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=256&q=80" 
                                    className="w-full h-full object-cover" 
                                    alt="User" 
                                />
                            </div>
                            <div>
                                <p className="text-[13px] font-medium mb-0.5" style={{ color: theme.textSecondary }}>Good Morning 👋</p>
                                <h1 className="text-[20px] font-extrabold leading-none tracking-tight" style={{ color: theme.text }}>Sarah Miller</h1>
                            </div>
                        </div>
                        <button 
                            onClick={() => setShowNotifications(true)}
                            className={`w-[46px] h-[46px] rounded-[16px] ${theme.cardBg} border ${theme.cardBorder} flex items-center justify-center relative hover:scale-[1.05] active:scale-95 transition-all shadow-sm`}
                        >
                            <Bell className="w-5 h-5" style={{ color: theme.text }} />
                            <span className="absolute top-3.5 right-3.5 w-2 h-2 bg-[#f49d9d] rounded-full border-2" style={{ borderColor: theme.phoneBg }} />
                        </button>
                    </div>

                    <div className="relative mb-3">
                      <Search
                        className="absolute left-[16px] top-1/2 -translate-y-1/2 w-4 h-4 transition-colors duration-500"
                        style={{ color: theme.textSecondary }}
                        strokeWidth={2.5}
                      />
                      <input
                        type="text"
                        placeholder="Search amazing projects..."
                        className={`w-full h-[48px] ${theme.inputBg} backdrop-blur-lg border-[1.5px] ${theme.inputBorder} rounded-[16px] pl-[44px] pr-[56px] text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
                        style={{ color: theme.text }}
                        value={searchQuery}
                        onChange={(e) =>
                          setSearchQuery(e.target.value)
                        }
                      />
                      <button 
                        onClick={() => setShowFilters(true)}
                        className="absolute right-1.5 top-1/2 -translate-y-1/2 bg-[#146068] rounded-[12px] w-[38px] h-[38px] flex items-center justify-center hover:scale-110 transition-transform shadow-lg active:scale-90"
                      >
                        <Filter
                          className="w-4 h-4 text-[#f4f3f1]"
                          strokeWidth={2.5}
                        />
                      </button>
                    </div>

                    <div
                      className="flex gap-2 overflow-x-auto pb-1"
                      style={{
                        scrollbarWidth: "none",
                        msOverflowStyle: "none",
                      }}
                    >
                      {categories.map((cat) => (
                        <button
                          key={cat.id}
                          onClick={() =>
                            setActiveCategory(cat.id)
                          }
                          className={`px-4 py-2 rounded-[12px] text-[13px] font-semibold whitespace-nowrap transition-all duration-300 active:scale-95 ${
                            activeCategory === cat.id
                              ? "bg-[#146068] text-[#f4f3f1] shadow-lg"
                              : `${theme.inputBg} backdrop-blur-lg border ${theme.inputBorder} hover:bg-[#f4f3f1]/15`
                          }`}
                          style={
                            activeCategory !== cat.id
                              ? { color: theme.text }
                              : {}
                          }
                        >
                          {cat.label}
                        </button>
                      ))}
                    </div>
                  </>
                ) : activeNav === "tender" ? (
                  <>
                    <div className="flex justify-between items-center mb-4">
                      <div>
                        <h1
                          className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500"
                          style={{ color: theme.text }}
                        >
                          Tenders
                        </h1>
                        <p
                          className="text-[13px] font-medium transition-colors duration-500"
                          style={{ color: theme.textSecondary }}
                        >
                          Open proposals & competitions
                        </p>
                      </div>
                      <div className="bg-[#f49d9d]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#f49d9d]/40">
                        <FileText
                          className="w-4 h-4 text-[#f49d9d]"
                          strokeWidth={2.5}
                        />
                      </div>
                    </div>
                  </>
                ) : activeNav === "booking" ? (
                  <>
                    <div className="flex justify-between items-center mb-4">
                      <div>
                        <h1
                          className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500"
                          style={{ color: theme.text }}
                        >
                          Bookings
                        </h1>
                        <p
                          className="text-[13px] font-medium transition-colors duration-500"
                          style={{ color: theme.textSecondary }}
                        >
                          Direct hire opportunities
                        </p>
                      </div>
                      <div className="bg-[#146068]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40">
                        <Calendar
                          className="w-4 h-4 text-[#146068]"
                          strokeWidth={2.5}
                        />
                      </div>
                    </div>
                  </>
                ) : activeNav === "messages" ? (
                  <>
                    <div className="flex justify-between items-center">
                      <div>
                        <h1
                          className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500"
                          style={{ color: theme.text }}
                        >
                          Messages
                        </h1>
                        <p
                          className="text-[13px] font-medium transition-colors duration-500"
                          style={{ color: theme.textSecondary }}
                        >
                          4 unread conversations
                        </p>
                      </div>
                      <button className="bg-[#146068]/30 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40 hover:bg-[#146068]/40 transition-all active:scale-95">
                        <Filter
                          className="w-4 h-4 text-[#f4f3f1]"
                          strokeWidth={2.5}
                        />
                      </button>
                    </div>
                  </>
                ) : activeNav === "orders" ? (
                  <>
                    <div className="flex justify-between items-center mb-2">
                       <div>
                          <h1 className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500" style={{ color: theme.text }}>
                             My Orders
                          </h1>
                          <p className="text-[13px] font-medium transition-colors duration-500" style={{ color: theme.textSecondary }}>
                             Track your active jobs
                          </p>
                       </div>
                       <div className="bg-[#146068]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40">
                          <Briefcase className="w-4 h-4 text-[#146068]" strokeWidth={2.5} />
                       </div>
                    </div>
                    {/* Status Tabs */}
                    <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-2`}>
                       {(["Active", "Revision", "Completed", "Cancelled"] as OrderStatus[]).map(status => (
                          <button
                             key={status}
                             onClick={() => setActiveOrderTab(status)}
                             className={`flex-1 py-2 rounded-[10px] text-[11px] font-bold transition-all duration-300 ${activeOrderTab === status ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                          >
                             {status}
                          </button>
                       ))}
                    </div>
                  </>
                ) : activeNav === "wallet" ? (
                  <>
                    <div className="flex justify-between items-center mb-4">
                       <div>
                          <h1 className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500" style={{ color: theme.text }}>
                             My Wallet
                          </h1>
                          <p className="text-[13px] font-medium transition-colors duration-500" style={{ color: theme.textSecondary }}>
                             Manage your earnings
                          </p>
                       </div>
                       <div className="bg-[#146068]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40">
                          <CreditCard className="w-4 h-4 text-[#146068]" strokeWidth={2.5} />
                       </div>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="flex justify-between items-center">
                      <div>
                        <h1
                          className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500"
                          style={{ color: theme.text }}
                        >
                          Profile
                        </h1>
                        <p
                          className="text-[13px] font-medium transition-colors duration-500"
                          style={{ color: theme.textSecondary }}
                        >
                          Manage your account
                        </p>
                      </div>
                      <button className="bg-[#146068] px-4 py-2 rounded-xl hover:bg-[#146068]/80 transition-all active:scale-95">
                        <span className="text-[12px] font-bold text-[#f4f3f1]">
                          Edit
                        </span>
                      </button>
                    </div>
                  </>
                )}
              </div>

              <div
                 className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                  scrollbarWidth: "thin",
                  scrollbarColor: theme.scrollbarColor,
                }}
              >
                   {activeNav === "wallet" && (
                     <div className="space-y-6 animate-fade-in">
                        {/* Glass Credit Card */}
                        <div className="w-full h-[200px] rounded-[24px] bg-gradient-to-br from-[#146068] to-[#0c3b40] relative overflow-hidden p-6 flex flex-col justify-between shadow-2xl border border-white/10">
                           <div className="absolute inset-0 bg-noise opacity-10 mix-blend-overlay" />
                           <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full blur-3xl -mr-10 -mt-10" />
                           <div className="absolute bottom-0 left-0 w-32 h-32 bg-[#f3bb19]/20 rounded-full blur-3xl -ml-10 -mb-10" />
                           
                           <div className="relative z-10 flex justify-between items-start">
                              <div>
                                 <span className="text-[12px] font-medium text-white/70 block mb-1">Total Balance</span>
                                 <h2 className="text-[32px] font-black text-white tracking-tight">${walletData.totalBalance}</h2>
                              </div>
                              <Wallet className="w-6 h-6 text-white/50" />
                           </div>
                           
                           <div className="relative z-10">
                              <div className="flex gap-8 mb-6">
                                 <div>
                                    <span className="text-[10px] font-bold text-white/60 block uppercase tracking-wide">Available</span>
                                    <span className="text-[14px] font-bold text-white">${walletData.availableBalance}</span>
                                 </div>
                                 <div>
                                    <span className="text-[10px] font-bold text-white/60 block uppercase tracking-wide">In Escrow</span>
                                    <span className="text-[14px] font-bold text-[#f3bb19]">${walletData.escrowBalance}</span>
                                 </div>
                              </div>
                              <div className="flex justify-between items-end">
                                 <div className="text-[12px] font-mono text-white/50">**** **** **** {walletData.cardLast4}</div>
                                 <div className="w-8 h-5 bg-white/20 rounded flex items-center justify-center">
                                    <div className="w-4 h-4 rounded-full bg-red-500/80 -mr-2 mix-blend-screen" />
                                    <div className="w-4 h-4 rounded-full bg-yellow-500/80 mix-blend-screen" />
                                 </div>
                              </div>
                           </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex gap-3">
                           <button className="flex-1 h-[50px] bg-[#f3bb19] rounded-[16px] text-black font-black text-[14px] shadow-lg shadow-[#f3bb19]/20 hover:scale-[1.02] active:scale-95 transition-transform flex items-center justify-center gap-2">
                              <ArrowUpRight className="w-4 h-4" /> Withdraw
                           </button>
                           <button className={`flex-1 h-[50px] ${theme.cardBg} border ${theme.cardBorder} rounded-[16px] font-bold text-[14px] hover:bg-white/5 active:scale-95 transition-transform flex items-center justify-center gap-2`} style={{ color: theme.text }}>
                              <Plus className="w-4 h-4" /> Top Up
                           </button>
                        </div>

                        {/* Transaction History */}
                        <div>
                           <div className="flex justify-between items-center mb-4">
                              <h3 className="text-[16px] font-bold" style={{ color: theme.text }}>Recent Transactions</h3>
                              <button className="text-[12px] font-bold text-[#146068]">View All</button>
                           </div>
                           <div className="space-y-3">
                              {walletData.transactions.map(tx => (
                                 <div key={tx.id} className={`${theme.cardBg} backdrop-blur-lg rounded-[16px] p-4 border ${theme.cardBorder} flex items-center justify-between`}>
                                    <div className="flex items-center gap-3">
                                       <div className={`w-10 h-10 rounded-full flex items-center justify-center border ${theme.cardBorder} ${tx.isPositive ? 'bg-[#146068]/20 text-[#146068]' : 'bg-[#f49d9d]/20 text-[#f49d9d]'}`}>
                                          {tx.isPositive ? <ArrowDownLeft className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
                                       </div>
                                       <div>
                                          <div className="text-[13px] font-bold mb-0.5" style={{ color: theme.text }}>{tx.description}</div>
                                          <div className="text-[11px]" style={{ color: theme.textSecondary }}>{tx.date}</div>
                                       </div>
                                    </div>
                                    <div className="text-right">
                                       <div className={`text-[14px] font-black ${tx.isPositive ? 'text-[#146068]' : 'text-[#f49d9d]'}`}>
                                          {tx.isPositive ? '+' : '-'}${tx.amount}
                                       </div>
                                       <div className={`text-[10px] font-bold uppercase ${tx.status === 'completed' ? 'text-[#93ccce]' : 'text-[#f3bb19]'}`}>
                                          {tx.status}
                                       </div>
                                    </div>
                                 </div>
                              ))}
                           </div>
                        </div>
                     </div>
                   )}
                   {activeNav === "orders" && (
                      <div className="space-y-4 animate-fade-in">
                         {orders.filter(o => o.status === activeOrderTab).length === 0 ? (
                            <div className="text-center py-10 opacity-50">
                               <div className="w-16 h-16 rounded-full bg-white/5 mx-auto flex items-center justify-center mb-4">
                                  <Briefcase className="w-8 h-8 opacity-50" />
                               </div>
                               <h3 className="text-lg font-bold" style={{ color: theme.text }}>No {activeOrderTab} Orders</h3>
                               <p className="text-sm" style={{ color: theme.textSecondary }}>You don't have any jobs in this status.</p>
                            </div>
                         ) : (
                            orders.filter(o => o.status === activeOrderTab).map(order => (
                               <div key={order.id} className={`${theme.cardBg} backdrop-blur-lg rounded-[20px] p-5 border ${theme.cardBorder} relative overflow-hidden`}>
                                  <div className="flex justify-between items-start mb-4">
                                     <div className="flex items-center gap-3">
                                        <div className="w-10 h-10 rounded-[12px] bg-[#f3bb19] flex items-center justify-center text-[13px] font-black text-black">
                                           {order.client.initials}
                                        </div>
                                        <div>
                                           <h3 className="text-[15px] font-bold leading-tight mb-0.5" style={{ color: theme.text }}>{order.title}</h3>
                                           <p className="text-[12px]" style={{ color: theme.textSecondary }}>Client: {order.client.name}</p>
                                        </div>
                                     </div>
                                     <div className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border ${order.status === 'Active' ? 'bg-[#146068]/20 text-[#93ccce] border-[#146068]/40' : order.status === 'Revision' ? 'bg-[#f3bb19]/20 text-[#f3bb19] border-[#f3bb19]/40' : 'bg-white/5 text-gray-400 border-white/10'}`}>
                                        {order.status.toUpperCase()}
                                     </div>
                                  </div>

                                  {/* Dashboard Metrics for Active Jobs */}
                                  {order.status === 'Active' && (
                                     <div className="flex gap-3 mb-4">
                                        <div className="flex-1 p-3 rounded-[14px] bg-[#146068]/10 border border-[#146068]/20 flex flex-col items-center">
                                           <Clock className="w-4 h-4 text-[#146068] mb-1" />
                                           <span className="text-[14px] font-black text-[#146068]">{order.timeLeft}</span>
                                           <span className="text-[9px] font-bold opacity-60 uppercase">Time Left</span>
                                        </div>
                                        <div className="flex-1 p-3 rounded-[14px] bg-white/5 border border-white/10 flex flex-col items-center">
                                           <DollarSign className="w-4 h-4 text-[#f4f3f1] mb-1" />
                                           <span className="text-[14px] font-black text-[#f4f3f1]">{order.price}</span>
                                           <span className="text-[9px] font-bold opacity-60 uppercase">Budget</span>
                                        </div>
                                     </div>
                                  )}

                                  {/* Actions */}
                                  <div className="pt-3 border-t border-white/10 flex gap-3">
                                     {(order.status === 'Active' || order.status === 'Revision') ? (
                                        <button className="flex-1 h-[40px] bg-[#146068] rounded-[12px] text-[12px] font-bold text-white shadow-lg hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2">
                                           <Upload className="w-4 h-4" /> Deliver Work
                                        </button>
                                     ) : (
                                        <button className="flex-1 h-[40px] bg-white/5 border border-white/10 rounded-[12px] text-[12px] font-bold text-white hover:bg-white/10 active:scale-95 transition-all">
                                           View Details
                                        </button>
                                     )}
                                     <button className="w-[40px] h-[40px] rounded-[12px] border border-white/10 flex items-center justify-center hover:bg-white/5 active:scale-95 transition-all">
                                        <MessageSquare className="w-4 h-4 text-white/70" />
                                     </button>
                                  </div>
                               </div>
                            ))
                         )}
                      </div>
                   )}
                   {activeNav === "tender" && (
                    <div className="space-y-3">
                       {tasks.filter(t => t.type === 'Tender').map(task => (
                           <div key={task.id} onClick={() => setSelectedTask(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
                              <div className="flex items-start justify-between mb-3 relative">
                              <div className="flex items-center gap-2">
                                <div className="w-9 h-9 rounded-full flex items-center justify-center font-bold text-[14px] text-white" style={{ backgroundColor: task.bgColor }}>{task.author.initials}</div>
                                <div>
                                  <div className="flex items-center gap-1">
                                    <span className="text-[13px] font-bold" style={{ color: theme.text }}>{task.author.name}</span>
                                    {task.author.verified && <span className="text-[12px]">✓</span>}
                                  </div>
                                  <span className="text-[10px] font-medium" style={{ color: theme.textSecondary }}>{task.author.time}</span>
                                </div>
                              </div>
                              <div className="bg-[#f49d9d]/20 px-2.5 py-1 rounded-lg flex items-center gap-1">
                                <FileText className="w-3 h-3 text-[#f49d9d]" strokeWidth={2.5} />
                                <span className="text-[10px] font-bold text-[#f49d9d]">TENDER</span>
                              </div>
                            </div>
                            <h3 className="text-[15px] font-extrabold mb-1.5" style={{ color: theme.text }}>{task.title}</h3>
                            <p className="text-[12px] mb-3 line-clamp-2" style={{ color: theme.textSecondary }}>{task.description}</p>
                            <div className="flex justify-between items-center pt-3 border-t" style={{ borderColor: theme.cardBorder }}>
                               <div className="flex items-center gap-3">
                                  <span className="text-[11px] font-bold text-[#f49d9d]">{task.timeLeft}</span>
                                  <span className="text-[11px] font-bold" style={{ color: theme.text }}>{task.offers || 0} offers</span>
                               </div>
                               <span className="text-[15px] font-extrabold text-[#146068]">{task.budget}</span>
                            </div>
                           </div>
                       ))}
                    </div>
                   )}
                   {activeNav === "booking" && (
                     <div className="space-y-3">
                       {tasks.filter(t => t.type === 'Booking').map(task => (
                           <div key={task.id} onClick={() => setSelectedTask(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
                              <div className="flex items-start justify-between mb-3 relative">
                              <div className="flex items-center gap-2">
                                <div className="w-9 h-9 rounded-full flex items-center justify-center font-bold text-[14px] text-white" style={{ backgroundColor: task.bgColor }}>{task.author.initials}</div>
                                <div>
                                  <div className="flex items-center gap-1">
                                    <span className="text-[13px] font-bold" style={{ color: theme.text }}>{task.author.name}</span>
                                    {task.author.verified && <span className="text-[12px]">✓</span>}
                                  </div>
                                  <span className="text-[10px] font-medium" style={{ color: theme.textSecondary }}>{task.author.time}</span>
                                </div>
                              </div>
                              <div className="bg-[#146068]/20 px-2.5 py-1 rounded-lg flex items-center gap-1">
                                <Calendar className="w-3 h-3 text-[#146068]" strokeWidth={2.5} />
                                <span className="text-[10px] font-bold text-[#146068]">BOOKING</span>
                              </div>
                            </div>
                            <h3 className="text-[15px] font-extrabold mb-1.5" style={{ color: theme.text }}>{task.title}</h3>
                            <p className="text-[12px] mb-3 line-clamp-2" style={{ color: theme.textSecondary }}>{task.description}</p>
                            <div className="flex justify-between items-center pt-3 border-t" style={{ borderColor: theme.cardBorder }}>
                               <div className="flex items-center gap-3">
                                  <span className="text-[11px] font-bold text-[#146068]">{task.timeLeft}</span>
                               </div>
                               <span className="text-[15px] font-extrabold text-[#146068]">{task.budget}</span>
                            </div>
                           </div>
                       ))}
                    </div>
                   )}
                   {activeNav === "home" && (
                      <div className="space-y-4 pb-4">
                      {tasks.map((task) => (
                        <div
                          key={task.id}
                          className={`${theme.cardBg} backdrop-blur-2xl rounded-[20px] overflow-hidden border ${theme.cardBorder} hover:${theme.cardBorderHover} hover:-translate-y-2 hover:scale-[1.02] active:scale-[0.98] transition-all duration-500 cursor-pointer`}
                           onClick={() => setSelectedTask(task)}
                        >
                           <div className="h-32 relative" style={{ backgroundColor: task.bgColor }}>
                             <div className={`absolute inset-0 bg-gradient-to-t ${theme.taskGradient} to-transparent`} />
                             {task.isHot && <div className="absolute top-3 left-3 bg-[#f49d9d] text-[#f4f3f1] px-2.5 py-1 rounded-lg text-[10px] font-extrabold uppercase tracking-wide shadow-lg">🔥 HOT</div>}
                             <div className="absolute top-3 right-3"><span className={`px-3 py-1.5 rounded-lg text-[10px] font-extrabold uppercase tracking-wider backdrop-blur-lg border shadow-lg ${task.type === "Tender" ? "bg-[#f49d9d]/90 text-[#f4f3f1] border-[#f4f3f1]/30" : "bg-[#146068]/90 text-[#f4f3f1] border-[#93ccce]/30"}`}>{task.type}</span></div>
                           </div>
                           <div className="p-4 relative">
                              <h3 className="text-[16px] font-extrabold mb-2" style={{ color: theme.text }}>{task.title}</h3>
                              <p className="text-[13px] leading-relaxed mb-3" style={{ color: theme.textSecondary }}>{task.description}</p>
                              <div className={`flex justify-between items-center pt-3 border-t ${theme.cardBorder}`}>
                                <span className="text-[18px] font-black text-[#146068]">{task.budget}</span>
                              </div>
                           </div>
                        </div>
                      ))}
                      </div>
                   )}
                   {activeNav === "messages" && (
                     <div className="space-y-3 pb-4">
                        {messages.map((message) => (
                           <div
                              key={message.id}
                              onClick={() => setSelectedChat(message)}
                              className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border transition-all duration-300 cursor-pointer hover:-translate-y-1 active:scale-[0.98] ${message.unread > 0 ? "border-[#146068]/40 bg-[#146068]/5" : `${theme.cardBorder} hover:${theme.cardBorderHover}`}`}
                           >
                              <div className="flex items-start gap-3">
                                 <div className="relative flex-shrink-0">
                                    <div className="w-[44px] h-[44px] rounded-[14px] bg-[#f3bb19] flex items-center justify-center text-[15px] font-extrabold text-[#0c0c0c] border-2 border-[#f4f3f1]/20">
                                       {message.initials}
                                    </div>
                                    {message.online && <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-[#93ccce] rounded-full border-2" style={{ borderColor: theme.phoneBg }} />}
                                 </div>
                                 <div className="flex-1 min-w-0">
                                    <div className="flex items-center justify-between mb-1">
                                       <div className="flex items-center gap-1.5">
                                          <h3 className="text-[14px] font-bold leading-tight" style={{ color: theme.text }}>{message.name}</h3>
                                          {message.verified && <svg width="12" height="12" fill="#93ccce" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" /></svg>}
                                       </div>
                                       <span className="text-[11px] font-semibold" style={{ color: theme.textSecondary }}>{message.time}</span>
                                    </div>
                                    <p className={`text-[13px] leading-relaxed line-clamp-2 ${message.unread > 0 ? "font-semibold" : ""}`} style={{ color: message.unread > 0 ? theme.text : theme.textSecondary }}>{message.lastMessage}</p>
                                 </div>
                                 {message.unread > 0 && (
                                    <div className="flex-shrink-0">
                                       <div className="w-6 h-6 rounded-full bg-[#146068] flex items-center justify-center">
                                          <span className="text-[11px] font-extrabold text-[#f4f3f1]">{message.unread}</span>
                                       </div>
                                    </div>
                                 )}
                              </div>
                           </div>
                        ))}
                     </div>
                   )}
                   {activeNav === "profile" && (
                    <>
                       {/* Profile content kept same */}
                       <div className={`${theme.cardBg} backdrop-blur-lg rounded-[20px] p-4 border ${theme.cardBorder} mb-4 transition-all duration-500`}>
                          <div className="flex items-center gap-4 mb-4">
                             <div className="w-[70px] h-[70px] rounded-[16px] bg-[#f3bb19] flex items-center justify-center text-[28px] font-extrabold text-[#0c0c0c] border-3 border-[#f4f3f1]/20 relative">
                                SM
                                <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#93ccce] rounded-full border-3" style={{ borderColor: theme.phoneBg }} />
                             </div>
                             <div className="flex-1">
                                <div className="flex items-center gap-2 mb-1">
                                   <h3 className="text-[18px] font-extrabold leading-tight" style={{ color: theme.text }}>Sarah Miller</h3>
                                   <svg width="16" height="16" fill="#93ccce" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" /></svg>
                                </div>
                                <p className="text-[13px] leading-tight mb-2" style={{ color: theme.textSecondary }}>Full Stack Developer</p>
                                <div className="flex items-center gap-2">
                                   <span className="text-[11px] bg-[#146068]/20 text-[#93ccce] px-2 py-1 rounded-lg font-semibold">⭐ Top Rated</span>
                                   <span className="text-[11px] bg-[#f3bb19]/20 text-[#f3bb19] px-2 py-1 rounded-lg font-semibold">🔥 Rising Talent</span>
                                </div>
                             </div>
                          </div>
                          <div className="grid grid-cols-3 gap-3">
                             {profileStats.map((stat, index) => (
                                <div key={index} className="rounded-[14px] p-3 text-center transition-colors duration-500" style={{ backgroundColor: isDarkMode ? "rgba(12, 12, 12, 0.2)" : "rgba(244, 243, 241, 0.5)" }}>
                                   <div className="text-[20px] font-black tracking-tight leading-none mb-1" style={{ color: stat.color }}>{stat.value}</div>
                                   <div className="text-[11px] font-semibold" style={{ color: theme.textSecondary }}>{stat.label}</div>
                                </div>
                             ))}
                          </div>
                       </div>
                       <div className="space-y-2.5 pb-4">
                          {profileMenuItems.map((item, index) => (
                             <div 
                                key={index} 
                                onClick={() => { if (item.label === "Payments") setActiveNav("wallet"); }}
                                className={`${theme.cardBg} backdrop-blur-lg rounded-[16px] p-4 border ${theme.cardBorder} hover:${theme.cardBorderHover} transition-all duration-300 cursor-pointer hover:-translate-y-0.5 flex items-center gap-3 active:scale-[0.98]`}
                             >
                                <div className="w-11 h-11 rounded-[12px] flex items-center justify-center flex-shrink-0" style={{ backgroundColor: `${item.color}20` }}>
                                   {renderIcon(item.icon, `w-5 h-5 text-[${item.color}]`)}
                                </div>
                                <div className="flex-1 min-w-0">
                                   <h3 className="text-[14px] font-bold leading-tight mb-0.5" style={{ color: theme.text }}>{item.label}</h3>
                                   <p className="text-[12px] leading-tight" style={{ color: theme.textSecondary }}>{item.description}</p>
                                </div>
                                {item.badge && <div className="flex-shrink-0"><div className="bg-[#146068]/20 px-2.5 py-1 rounded-lg"><span className="text-[11px] font-bold text-[#146068]">{item.badge}</span></div></div>}
                                <ArrowUpRight className="w-4 h-4 flex-shrink-0" style={{ color: theme.textSecondary }} />
                             </div>
                          ))}
                          <div className={`${theme.cardBg} backdrop-blur-lg rounded-[16px] p-4 border ${theme.cardBorder} flex items-center gap-3 transition-all duration-500`}>
                             <div className="w-11 h-11 rounded-[12px] bg-[#146068]/20 flex items-center justify-center flex-shrink-0"><span className="text-[20px]">{isDarkMode ? "🌙" : "☀️"}</span></div>
                             <div className="flex-1 min-w-0">
                                <h3 className="text-[14px] font-bold leading-tight mb-0.5" style={{ color: theme.text }}>Dark Mode</h3>
                                <p className="text-[12px] leading-tight" style={{ color: theme.textSecondary }}>Switch between themes</p>
                             </div>
                             <button onClick={() => setIsDarkMode(!isDarkMode)} className={`relative w-14 h-7 rounded-full transition-all duration-300 flex-shrink-0 ${isDarkMode ? "bg-[#146068]" : "bg-[#9dbabb]"}`}><div className={`absolute top-0.5 w-6 h-6 rounded-full bg-[#f4f3f1] shadow-lg transition-all duration-300 ${isDarkMode ? "right-0.5" : "left-0.5"}`} /></button>
                          </div>
                       </div>
                       <button onClick={() => setIsLoggedIn(false)} className="w-full bg-[#f49d9d]/10 border border-[#f49d9d]/30 rounded-[16px] p-4 text-[14px] font-bold text-[#f49d9d] hover:-translate-y-0.5 transition-all duration-300 active:scale-95">Logout</button>
                    </>
                   )}
              </div>

               {/* FAB & Bottom Nav */}
               <button onClick={() => setShowCreateTask(true)} className="absolute bottom-[100px] right-6 w-14 h-14 rounded-[18px] bg-[#146068] shadow-2xl flex items-center justify-center hover:scale-110 active:scale-90 hover:rotate-90 transition-all duration-400 z-30">
                <Plus className="w-7 h-7 text-[#f4f3f1]" strokeWidth={3} />
               </button>
               
               <div className="absolute bottom-6 left-6 right-6 h-[80px] rounded-[30px] flex justify-around items-center px-1 z-40 transition-all duration-500 overflow-hidden backdrop-blur-xl animate-fade-in" style={{ background: isDarkMode ? "linear-gradient(to bottom, rgba(20, 96, 104, 0.2), rgba(0, 0, 0, 0.4))" : "linear-gradient(to bottom, rgba(255, 255, 255, 0.7), rgba(255, 255, 255, 0.4))", boxShadow: isDarkMode ? "0 20px 40px -10px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1), inset 0 -1px 0 rgba(0,0,0,0.2)" : "0 20px 40px -10px rgba(147, 204, 206, 0.4), inset 0 1px 0 rgba(255,255,255,0.8)", border: isDarkMode ? "1px solid rgba(255,255,255,0.08)" : "1px solid rgba(255,255,255,0.6)", backdropFilter: "blur(20px)" }}>
                 {[ 
                   { id: "home", icon: Home }, 
                   { id: "tender", icon: FileText }, 
                   { id: "booking", icon: Calendar }, 
                   { id: "orders", icon: Briefcase }, // NEW: Orders Tab
                   { id: "messages", icon: MessageCircle, hasNotification: true }, 
                   { id: "profile", icon: User } 
                  ].map((item) => (
                    <button key={item.id} onClick={() => setActiveNav(item.id as NavView)} className="flex flex-col items-center gap-1 px-2 py-2 rounded-2xl transition-all duration-300 relative group z-10 active:animate-spring">
                       <item.icon className={`w-[22px] h-[22px] transition-all duration-300 drop-shadow-lg ${activeNav === item.id || (activeNav === "wallet" && item.id === "profile") ? "text-[#f4f3f1] scale-110" : "text-[#f4f3f1]/60"}`} strokeWidth={activeNav === item.id ? 2.5 : 2} />
                       {item.hasNotification && <div className="absolute top-1 right-2 w-2 h-2 bg-[#f49d9d] rounded-full" />}
                    </button>
                 ))}
               </div>
            </div>

             {/* Notification Center */}
             {showNotifications && (
                 <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex justify-end animate-fade-in" onClick={() => setShowNotifications(false)}>
                    <div className={`w-[85%] h-full ${theme.cardBg} border-l ${theme.cardBorder} backdrop-blur-2xl flex flex-col animate-slide-up`} onClick={e => e.stopPropagation()}>
                       <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />
                       <div className={`px-6 pt-12 pb-4 border-b ${theme.headerBorder} flex justify-between items-center relative z-10`}>
                          <h2 className="text-[20px] font-bold" style={{ color: theme.text }}>Notifications</h2>
                          <button onClick={() => setShowNotifications(false)} className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10"><X className="w-5 h-5" style={{ color: theme.text }} /></button>
                       </div>
                       <div className="flex-1 overflow-y-auto px-4 py-4 space-y-6 relative z-10">
                           {['Today', 'Yesterday'].map(group => (
                               <div key={group}>
                                   <h3 className="text-[12px] font-bold uppercase tracking-wider mb-3 opacity-60 px-2" style={{ color: theme.text }}>{group}</h3>
                                   <div className="space-y-3">
                                       {notifications.filter(n => n.group === group).map(notification => (
                                           <div key={notification.id} className={`p-4 rounded-[16px] ${theme.inputBg} border ${theme.cardBorder} relative overflow-hidden`}>
                                               <div className="flex gap-3">
                                                   <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white ${notification.type === 'order' ? 'bg-[#146068]' : notification.type === 'payment' ? 'bg-[#f3bb19]' : notification.type === 'system' ? 'bg-gray-500' : 'bg-[#93ccce]'}`}>
                                                       {notification.type === 'order' && <Briefcase className="w-5 h-5" />}
                                                       {notification.type === 'payment' && <DollarSign className="w-5 h-5" />}
                                                       {notification.type === 'proposal' && <FileText className="w-5 h-5" />}
                                                       {notification.type === 'system' && <AlertCircle className="w-5 h-5" />}
                                                   </div>
                                                   <div className="flex-1">
                                                       <div className="flex justify-between items-start mb-1">
                                                           <h4 className="text-[14px] font-bold leading-tight" style={{ color: theme.text }}>{notification.title}</h4>
                                                           <span className="text-[10px] font-medium opacity-60" style={{ color: theme.textSecondary }}>{notification.time}</span>
                                                       </div>
                                                       <p className="text-[12px] leading-snug" style={{ color: theme.textSecondary }}>{notification.message}</p>
                                                   </div>
                                               </div>
                                               {!notification.isRead && <div className="absolute top-4 right-2 w-2 h-2 rounded-full bg-[#f49d9d]" />}
                                           </div>
                                       ))}
                                   </div>
                               </div>
                           ))}
                       </div>
                    </div>
                 </div>
             )}

             {/* Advanced Search Filters Modal - Refined with visual sliders */}
             {showFilters && (
                 <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowFilters(false)}>
                    <div className={`w-full ${theme.cardBg} rounded-t-[30px] p-6 border-t ${theme.cardBorder} animate-slide-up flex flex-col max-h-[85vh] relative overflow-hidden`} onClick={e => e.stopPropagation()}>
                        <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />
                        
                        <div className="relative z-10">
                            <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mb-6" />
                            <div className="flex justify-between items-center mb-6">
                                <h3 className="text-[20px] font-bold" style={{ color: theme.text }}>Filters</h3>
                                <button className="text-[12px] font-bold text-[#146068]" onClick={() => setFilters({minBudget: '', maxBudget: '', deliveryTime: [], sellerLevel: [], sortBy: 'Relevance'})}>Reset All</button>
                            </div>
                            
                            <div className="flex-1 overflow-y-auto space-y-6 mb-6">
                                {/* Sort By */}
                                <div>
                                    <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Sort By</label>
                                    <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
                                        {['Relevance', 'Newest', 'Price: Low to High', 'Price: High to Low'].map(sort => (
                                            <button 
                                                key={sort}
                                                onClick={() => setFilters({...filters, sortBy: sort})}
                                                className={`px-4 py-2 rounded-[12px] text-[12px] font-bold border whitespace-nowrap transition-all ${filters.sortBy === sort ? 'bg-[#146068] border-[#146068] text-white' : `${theme.inputBg} ${theme.inputBorder}`}`}
                                                style={filters.sortBy !== sort ? { color: theme.textSecondary } : {}}
                                            >
                                                {sort}
                                            </button>
                                        ))}
                                    </div>
                                </div>

                                {/* Budget Range with Visual Slider */}
                                <div>
                                    <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Budget Range</label>
                                    <div className="px-1 mb-4">
                                        <input 
                                            type="range" 
                                            min="0" 
                                            max="5000" 
                                            value={filters.maxBudget || 1000} 
                                            onChange={(e) => setFilters({...filters, maxBudget: e.target.value})}
                                            className="w-full h-2 bg-gray-500/20 rounded-lg appearance-none cursor-pointer accent-[#146068]" 
                                        />
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <div className="flex-1 relative">
                                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span>
                                            <input type="number" placeholder="Min" value={filters.minBudget} onChange={e => setFilters({...filters, minBudget: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} />
                                        </div>
                                        <span className="opacity-50">-</span>
                                        <div className="flex-1 relative">
                                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span>
                                            <input type="number" placeholder="Max" value={filters.maxBudget} onChange={e => setFilters({...filters, maxBudget: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} />
                                        </div>
                                    </div>
                                </div>

                                {/* Delivery Time */}
                                <div>
                                    <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Delivery Time</label>
                                    <div className="flex flex-wrap gap-2">
                                        {['Up to 24h', 'Up to 3 days', 'Up to 7 days', 'Anytime'].map(time => (
                                            <button 
                                                key={time} 
                                                onClick={() => toggleFilter('deliveryTime', time)}
                                                className={`px-4 py-2 rounded-[12px] text-[12px] font-bold border transition-all ${filters.deliveryTime.includes(time) ? 'bg-[#146068] border-[#146068] text-white' : `${theme.inputBg} ${theme.inputBorder}`}`}
                                                style={!filters.deliveryTime.includes(time) ? { color: theme.textSecondary } : {}}
                                            >
                                                {time}
                                            </button>
                                        ))}
                                    </div>
                                </div>

                                {/* Seller Level */}
                                <div>
                                    <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Seller Level</label>
                                    <div className="space-y-2">
                                        {['Top Rated Seller', 'Level 2', 'Level 1', 'New Seller'].map(level => (
                                            <button 
                                                key={level}
                                                onClick={() => toggleFilter('sellerLevel', level)}
                                                className={`w-full flex items-center justify-between p-3 rounded-[14px] border ${filters.sellerLevel.includes(level) ? 'bg-[#146068]/10 border-[#146068] text-[#146068]' : `${theme.inputBg} ${theme.inputBorder}`}`}
                                            >
                                                <span className={`text-[13px] font-medium ${filters.sellerLevel.includes(level) ? 'text-[#146068]' : ''}`} style={{ color: !filters.sellerLevel.includes(level) ? theme.text : undefined }}>{level}</span>
                                                {filters.sellerLevel.includes(level) && <Check className="w-4 h-4" />}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            <button onClick={() => setShowFilters(false)} className="w-full h-[54px] bg-[#146068] rounded-[16px] text-[16px] font-bold text-white shadow-xl hover:scale-[1.02] active:scale-95 transition-all">
                                Apply Filters
                            </button>
                        </div>
                    </div>
                 </div>
             )}

             {/* Chat View, Task Details View, Proposal Details View, Create Task Screen components remain unchanged but included in logic */}
             {selectedChat && (
                // ... chat overlay logic ...
                <div className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 animate-slide-up overflow-hidden" style={{ backgroundColor: theme.phoneBg }}>
                   <div className={`px-4 pt-8 pb-3 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-20`}>
                      <button onClick={() => setSelectedChat(null)} className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95"><ChevronLeft className="w-6 h-6" style={{ color: theme.text }} /></button>
                      <h2 className="text-[15px] font-bold">{selectedChat.name}</h2>
                       <button onClick={() => setShowOfferModal(true)} className="flex items-center gap-1 bg-[#146068] px-3 py-1.5 rounded-full text-white active:scale-95 transition-transform"><DollarSign className="w-4 h-4" /><span className="text-[11px] font-bold">Offer</span></button>
                   </div>
                   <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 relative z-10">
                      {selectedChat.history?.map((msg) => (
                         <div key={msg.id} className={`flex flex-col ${msg.sender === 'me' ? 'items-end' : 'items-start'}`}>
                            {msg.type === 'offer' && msg.offer ? (
                               <div className="max-w-[85%] bg-[#146068]/10 border border-[#146068]/30 backdrop-blur-md rounded-[20px] p-4 mb-1">
                                  <div className="flex justify-between items-start mb-2">
                                     <div className="bg-[#146068] text-white text-[10px] font-bold px-2 py-0.5 rounded-md uppercase">Custom Offer</div>
                                     <div className="text-[#146068] font-black text-[16px]">{msg.offer.price}</div>
                                  </div>
                                  <h3 className="text-[14px] font-bold mb-1" style={{ color: theme.text }}>{msg.offer.title}</h3>
                                  <p className="text-[12px] mb-3 leading-relaxed" style={{ color: theme.textSecondary }}>{msg.offer.description}</p>
                                  <div className="flex items-center gap-1 text-[11px] font-medium mb-3" style={{ color: theme.textSecondary }}><Clock className="w-3 h-3" /> {msg.offer.deliveryTime} Delivery</div>
                                  <div className="flex gap-2">
                                     <button className="flex-1 bg-[#146068] text-white h-[36px] rounded-[10px] text-[12px] font-bold hover:scale-[1.02] active:scale-95 transition-transform">Accept</button>
                                     <button className="flex-1 bg-transparent border border-[#146068]/30 h-[36px] rounded-[10px] text-[12px] font-bold hover:bg-[#146068]/5 active:scale-95 transition-all" style={{ color: theme.text }}>Decline</button>
                                  </div>
                               </div>
                            ) : (
                               <div className={`max-w-[80%] px-4 py-2.5 rounded-[18px] text-[14px] leading-relaxed ${msg.sender === 'me' ? 'bg-[#146068] text-white' : `${theme.cardBg} border ${theme.cardBorder}`}`} style={msg.sender === 'them' ? { color: theme.text } : {}}>{msg.text}</div>
                            )}
                            <span className="text-[10px] mt-1 px-1 opacity-60" style={{ color: theme.textSecondary }}>{msg.time}</span>
                         </div>
                      ))}
                   </div>
                    <div className={`px-4 py-3 pb-8 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-20`}>
                       <div className="flex items-center gap-2">
                          <button className="p-2 rounded-full hover:bg-white/10 text-[#146068]"><Paperclip className="w-5 h-5" /></button>
                          <input type="text" placeholder="Type a message..." className={`flex-1 h-[46px] rounded-full ${theme.inputBg} border ${theme.inputBorder} px-4`} style={{ color: theme.text }} />
                          <button className="p-3 rounded-full bg-[#146068] text-white"><Send className="w-5 h-5" /></button>
                       </div>
                    </div>
                     {/* Create Offer Modal */}
                     {showOfferModal && (
                        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowOfferModal(false)}>
                           <div className={`w-full ${theme.cardBg} rounded-t-[30px] p-6 border-t ${theme.cardBorder} animate-slide-up`} onClick={e => e.stopPropagation()}>
                              <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mb-6" />
                              <h3 className="text-[18px] font-bold mb-4" style={{ color: theme.text }}>Create Custom Offer</h3>
                              <div className="space-y-4 mb-6">
                                 <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Title</label><input type="text" value={offerForm.title} onChange={e => setOfferForm({...offerForm, title: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                 <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Description</label><textarea value={offerForm.description} onChange={e => setOfferForm({...offerForm, description: e.target.value})} className={`w-full h-[80px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} p-3 text-[14px] outline-none resize-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                 <div className="flex gap-3">
                                    <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Price ($)</label><input type="number" value={offerForm.price} onChange={e => setOfferForm({...offerForm, price: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                    <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Delivery (Days)</label><input type="number" value={offerForm.deliveryTime} onChange={e => setOfferForm({...offerForm, deliveryTime: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                 </div>
                              </div>
                              <button onClick={handleSendOffer} className="w-full h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-white hover:scale-[1.02] active:scale-95 transition-all shadow-lg">Send Offer</button>
                           </div>
                        </div>
                     )}
                </div>
             )}

            {/* Task Details View */}
            {selectedTask && !selectedProposal && (
              <div 
                className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up"
                style={{ backgroundColor: theme.phoneBg }}
              >
                {/* Header ... */}
                <div className={`px-4 pt-8 pb-4 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-10`}>
                  <button 
                    onClick={() => { setSelectedTask(null); setSelectedPackageTier('Basic'); }}
                    className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95"
                  >
                    <ChevronLeft className="w-6 h-6" style={{ color: theme.text }} />
                  </button>
                  <h2 className="text-[17px] font-bold" style={{ color: theme.text }}>
                    {selectedTask.type === 'Booking' ? 'Booking Details' : 'Job Details'}
                  </h2>
                  <div className="flex gap-2">
                    <button className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95">
                      <Share className="w-5 h-5" style={{ color: theme.text }} />
                    </button>
                  </div>
                </div>
                
                 <div className="flex-1 overflow-y-auto px-5 py-6 relative z-10" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
                    <h1 className="text-[22px] font-extrabold leading-tight mb-3" style={{ color: theme.text }}>{selectedTask.title}</h1>
                    
                    {/* Author / Freelancer Card */}
                    <div 
                      className="flex items-center gap-3 mb-6 cursor-pointer group"
                      onClick={() => setSelectedUserProfile(mockFreelancerProfile)}
                    >
                        <div className="w-10 h-10 rounded-full bg-[#f3bb19] flex items-center justify-center text-[13px] font-black text-[#0c0c0c] border-2 border-[#f4f3f1]/20 relative group-active:scale-95 transition-transform">
                            {selectedTask.author.initials}
                            <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-[#93ccce] rounded-full border-2 border-[#0c0c0c]" />
                        </div>
                        <div>
                            <div className="flex items-center gap-1.5">
                                <h3 className="text-[14px] font-bold" style={{ color: theme.text }}>{selectedTask.author.name}</h3>
                                {selectedTask.author.verified && <CheckCircle2 className="w-3.5 h-3.5 text-[#93ccce]" fill="#93ccce" stroke="#0c0c0c" />}
                            </div>
                            <div className="text-[11px] font-medium text-[#146068]">View Profile</div>
                        </div>
                    </div>

                    {/* Service Packages Toggle for Booking */}
                    {selectedTask.type === 'Booking' && selectedTask.packages && (
                      <div className="mb-6">
                         <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-4`}>
                            {(['Basic', 'Standard', 'Premium'] as ServiceTier[]).map(tier => (
                               <button
                                  key={tier}
                                  onClick={() => setSelectedPackageTier(tier)}
                                  className={`flex-1 py-2.5 rounded-[10px] text-[12px] font-bold transition-all duration-300 ${selectedPackageTier === tier ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                               >
                                  {tier}
                               </button>
                            ))}
                         </div>
                         <div className={`p-5 rounded-[18px] ${theme.cardBg} border ${theme.cardBorder} relative overflow-hidden`}>
                            <div className="flex justify-between items-start mb-2">
                               <h3 className="text-[18px] font-black text-[#146068]">{currentPackage?.price}</h3>
                               <span className="text-[11px] font-bold bg-[#146068]/20 text-[#146068] px-2 py-1 rounded-lg uppercase tracking-wide">{currentPackage?.tier}</span>
                            </div>
                            <p className="text-[13px] leading-relaxed mb-4" style={{ color: theme.textSecondary }}>{currentPackage?.description}</p>
                            <div className="flex items-center gap-4 text-[12px] font-semibold" style={{ color: theme.text }}>
                                <div className="flex items-center gap-1.5"><Clock className="w-4 h-4 text-[#146068]" /> {currentPackage?.deliveryTime} Delivery</div>
                               <div className="flex items-center gap-1.5"><Repeat className="w-4 h-4 text-[#146068]" /> {currentPackage?.revisions} Revisions</div>
                            </div>
                         </div>
                      </div>
                    )}

                    <p className="text-[14px] leading-relaxed whitespace-pre-line mb-8" style={{ color: theme.textSecondary }}>{selectedTask.description}</p>
                    
                    {/* Received Proposals Section (Only for Tender) */}
                    {selectedTask.type === 'Tender' && selectedTask.proposals && (
                      <div className="mb-8 animate-fade-in">
                        <div className="flex items-center justify-between mb-4">
                           <h3 className="text-[16px] font-bold" style={{ color: theme.text }}>Received Proposals</h3>
                           <span className="text-[12px] font-bold bg-[#146068]/20 text-[#146068] px-2 py-1 rounded-lg">{selectedTask.proposals.length} New</span>
                        </div>
                        <div className="space-y-3">
                           {selectedTask.proposals.map(proposal => (
                             <div 
                               key={proposal.id}
                               onClick={() => setSelectedProposal(proposal)}
                               className={`${theme.cardBg} border ${theme.cardBorder} p-4 rounded-[16px] flex items-center justify-between cursor-pointer active:scale-[0.98] transition-all hover:bg-white/5`}
                             >
                                <div className="flex items-center gap-3">
                                   <div className="w-10 h-10 rounded-full bg-[#f3bb19] flex items-center justify-center text-[12px] font-bold text-black border-2 border-white/20" onClick={(e) => { e.stopPropagation(); setSelectedUserProfile(mockFreelancerProfile); }}>
                                      {proposal.freelancer.initials}
                                   </div>
                                   <div>
                                      <div className="text-[14px] font-bold" style={{ color: theme.text }}>{proposal.freelancer.name}</div>
                                      <div className="flex items-center gap-1 text-[11px]" style={{ color: theme.textSecondary }}>
                                         <span>⭐ {proposal.freelancer.rating}</span>
                                         <span>• {proposal.submittedAt}</span>
                                      </div>
                                   </div>
                                </div>
                                <div className="text-right">
                                   <div className="text-[14px] font-black text-[#146068]">{proposal.bidAmount}</div>
                                   <div className="text-[11px]" style={{ color: theme.textSecondary }}>{proposal.deliveryTime}</div>
                                </div>
                             </div>
                           ))}
                        </div>
                      </div>
                    )}
                 </div>

                 <div className={`px-6 py-4 pb-6 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-10`}>
                  <div className="flex gap-3">
                    <button 
                       onClick={() => {
                          if (selectedTask.type === 'Tender') {
                             setShowProposalModal(true);
                          } else {
                             console.log(`Booking package: ${selectedPackageTier}`);
                          }
                       }}
                       className={`flex-1 h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-[#f4f3f1] shadow-lg shadow-[#146068]/20 hover:scale-[1.02] active:scale-95 transition-transform flex items-center justify-center gap-2`}
                    >
                      {selectedTask.type === 'Booking' ? (
                         <>Book {selectedPackageTier} <span className="opacity-70">({currentPackage?.price})</span></>
                      ) : 'Apply Now'}
                    </button>
                    <button className={`h-[50px] px-6 ${theme.cardBg} border ${theme.cardBorder} rounded-[14px] text-[14px] font-bold flex items-center gap-2 hover:bg-white/5 active:scale-95 transition-all`} style={{ color: theme.text }}>
                      <Heart className="w-5 h-5" />
                    </button>
                  </div>
                </div>
                {/* Submit Proposal Modal */}
                {showProposalModal && (
                   <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowProposalModal(false)}>
                      <div className={`w-full h-[90%] ${theme.cardBg} rounded-t-[30px] flex flex-col border-t ${theme.cardBorder} animate-slide-up`} onClick={e => e.stopPropagation()}>
                         <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mt-3 mb-2" />
                         <div className={`px-6 py-4 border-b ${theme.headerBorder}`}>
                            <h2 className="text-[20px] font-bold" style={{ color: theme.text }}>Submit Proposal</h2>
                            <p className="text-[12px] truncate opacity-70" style={{ color: theme.textSecondary }}>Applying to: {selectedTask.title}</p>
                         </div>
                         <div className="flex-1 overflow-y-auto px-6 py-4 space-y-6">
                            {/* Bid Details */}
                            <div className="grid grid-cols-2 gap-4">
                               <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Bid Amount</label><div className="relative"><span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span><input type="text" placeholder={selectedTask.budget.replace('$','')} value={proposalForm.bidAmount} onChange={e => setProposalForm({...proposalForm, bidAmount: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} /></div></div>
                               <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Delivery Time</label><input type="text" placeholder="e.g. 7 Days" value={proposalForm.deliveryTime} onChange={e => setProposalForm({...proposalForm, deliveryTime: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} /></div>
                            </div>
                            {/* Cover Letter */}
                            <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Cover Letter</label><textarea placeholder="Explain why you are the best fit for this job..." value={proposalForm.coverLetter} onChange={e => setProposalForm({...proposalForm, coverLetter: e.target.value})} className={`w-full h-[200px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} p-4 outline-none resize-none focus:border-[#146068] leading-relaxed`} style={{ color: theme.text }} /></div>
                            {/* Attachments Placeholder */}
                            <div className={`h-[100px] rounded-[14px] border-2 border-dashed ${theme.inputBorder} flex flex-col items-center justify-center gap-2 opacity-60`}>
                               <Upload className="w-6 h-6" />
                               <span className="text-[12px] font-bold">Upload Files (Drag & Drop)</span>
                            </div>
                         </div>
                         <div className={`px-6 py-4 border-t ${theme.bottomNavBorder} ${theme.bottomNavBg}`}>
                            <button onClick={handleSubmitProposal} className="w-full h-[54px] bg-[#146068] rounded-[16px] text-[16px] font-bold text-white shadow-xl hover:scale-[1.02] active:scale-95 transition-all">Submit Proposal</button>
                         </div>
                      </div>
                   </div>
                )}
              </div>
            )}
            
            {/* Proposal Details (Client View) */}
            {selectedProposal && !selectedUserProfile && (
              <div className="absolute inset-0 z-[60] flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
                 <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none mix-blend-overlay z-0" />
                 
                 <div className={`px-4 pt-8 pb-4 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-10`}>
                    <button onClick={() => setSelectedProposal(null)} className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95">
                      <ChevronLeft className="w-6 h-6" style={{ color: theme.text }} />
                    </button>
                    <h2 className="text-[17px] font-bold" style={{ color: theme.text }}>Proposal Details</h2>
                    <div className="w-10"></div>
                 </div>

                 <div className="flex-1 overflow-y-auto px-5 py-6 relative z-10" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
                    <div className={`p-4 rounded-[20px] ${theme.cardBg} border ${theme.cardBorder} mb-6 flex items-start justify-between cursor-pointer hover:bg-white/5 active:scale-[0.98] transition-all`} onClick={() => setSelectedUserProfile(mockFreelancerProfile)}>
                       <div className="flex gap-4">
                          <div className="w-[60px] h-[60px] rounded-[18px] bg-[#f3bb19] flex items-center justify-center text-[20px] font-extrabold text-[#0c0c0c] border-2 border-[#f4f3f1]/20 relative">
                             {selectedProposal.freelancer.initials}
                             {selectedProposal.freelancer.online && <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-[#93ccce] rounded-full border-2 border-black" />}
                          </div>
                          <div>
                             <h3 className="text-[18px] font-bold leading-tight" style={{ color: theme.text }}>{selectedProposal.freelancer.name}</h3>
                             <div className="flex items-center gap-2 text-[13px] mb-1" style={{ color: theme.textSecondary }}>
                                <MapPin className="w-3.5 h-3.5" /> {selectedProposal.freelancer.location}
                             </div>
                             <div className="flex items-center gap-2">
                                <span className="bg-[#f3bb19]/20 text-[#f3bb19] px-2 py-0.5 rounded text-[11px] font-bold">⭐ {selectedProposal.freelancer.rating}</span>
                                {selectedProposal.freelancer.verified && <span className="bg-[#93ccce]/20 text-[#93ccce] px-2 py-0.5 rounded text-[11px] font-bold">Verified</span>}
                             </div>
                          </div>
                       </div>
                       <button className="w-10 h-10 rounded-full bg-[#146068]/20 flex items-center justify-center text-[#146068]">
                          <User className="w-5 h-5" />
                       </button>
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-6">
                       <div className={`p-4 rounded-[16px] bg-[#146068]/10 border border-[#146068]/20 text-center`}>
                          <div className="text-[12px] font-bold mb-1" style={{ color: theme.textSecondary }}>Bid Amount</div>
                          <div className="text-[22px] font-black text-[#146068]">{selectedProposal.bidAmount}</div>
                       </div>
                       <div className={`p-4 rounded-[16px] ${theme.cardBg} border ${theme.cardBorder} text-center`}>
                          <div className="text-[12px] font-bold mb-1" style={{ color: theme.textSecondary }}>Delivery Time</div>
                          <div className="text-[22px] font-black" style={{ color: theme.text }}>{selectedProposal.deliveryTime}</div>
                       </div>
                    </div>

                    <div className="mb-8">
                       <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Cover Letter</h3>
                       <p className="text-[14px] leading-relaxed whitespace-pre-line p-4 rounded-[16px] border border-dashed border-gray-500/20" style={{ color: theme.textSecondary }}>
                          {selectedProposal.coverLetter}
                       </p>
                    </div>

                    {selectedProposal.attachments.length > 0 && (
                      <div className="mb-8">
                         <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Attachments</h3>
                         <div className="space-y-2">
                            {selectedProposal.attachments.map((file, i) => (
                               <div key={i} className={`flex items-center justify-between p-3 rounded-[12px] ${theme.cardBg} border ${theme.cardBorder}`}>
                                  <div className="flex items-center gap-3">
                                     <div className="w-8 h-8 rounded-lg bg-[#f49d9d]/20 flex items-center justify-center text-[#f49d9d]">
                                        <FileText className="w-4 h-4" />
                                     </div>
                                     <span className="text-[13px] font-medium" style={{ color: theme.text }}>{file}</span>
                                  </div>
                                  <button className="p-2 hover:bg-white/10 rounded-full">
                                     <Download className="w-4 h-4" style={{ color: theme.textSecondary }} />
                                  </button>
                               </div>
                            ))}
                         </div>
                      </div>
                    )}
                 </div>

                 <div className={`px-6 py-4 pb-6 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-10`}>
                    <div className="flex gap-3">
                       <button className="flex-1 h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-white shadow-lg shadow-[#146068]/20 hover:scale-[1.02] active:scale-95 transition-transform">
                          Accept Offer
                       </button>
                       <button className={`flex-1 h-[50px] rounded-[14px] text-[14px] font-bold border ${theme.cardBorder} hover:bg-white/5 active:scale-95 transition-transform`} style={{ color: theme.text }}>
                          Decline
                       </button>
                    </div>
                 </div>
              </div>
            )}
            
            {/* Public Profile Overlay */}
            {selectedUserProfile && (
               <div className="absolute inset-0 z-[70] flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
                  <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none mix-blend-overlay z-0" />
                  
                  {/* Header Image */}
                  <div className="h-[120px] w-full bg-gradient-to-r from-[#146068] to-[#93ccce] relative z-0">
                     <button onClick={() => setSelectedUserProfile(null)} className="absolute top-8 left-4 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md flex items-center justify-center text-white active:scale-95 transition-transform">
                        <ChevronLeft className="w-6 h-6" />
                     </button>
                  </div>

                  <div className="flex-1 overflow-y-auto px-5 relative z-10 -mt-12 pb-24" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
                     {/* Hero Card */}
                     <div className={`${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} rounded-[24px] p-5 shadow-xl mb-6`}>
                        <div className="flex justify-between items-start mb-4">
                           <div className="w-[80px] h-[80px] rounded-[24px] bg-[#f3bb19] border-4 border-[#0c0c0c] flex items-center justify-center text-[28px] font-extrabold text-[#0c0c0c] -mt-10 shadow-lg relative">
                              {selectedUserProfile.initials}
                              {selectedUserProfile.online && <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#93ccce] rounded-full border-2 border-[#0c0c0c]" />}
                           </div>
                           <div className="flex gap-2">
                              <button className="w-10 h-10 rounded-full bg-[#146068]/10 flex items-center justify-center text-[#146068] hover:bg-[#146068]/20 transition-colors">
                                 <Share className="w-5 h-5" />
                              </button>
                              <button className="w-10 h-10 rounded-full bg-[#f49d9d]/10 flex items-center justify-center text-[#f49d9d] hover:bg-[#f49d9d]/20 transition-colors">
                                 <Heart className="w-5 h-5" />
                              </button>
                           </div>
                        </div>
                        
                        <div className="mb-4">
                           <h2 className="text-[22px] font-black leading-tight mb-1" style={{ color: theme.text }}>
                              {selectedUserProfile.name} 
                              {selectedUserProfile.verified && <span className="inline-block ml-1 align-middle"><CheckCircle2 className="w-5 h-5 text-[#93ccce]" fill="#93ccce" stroke="#0c0c0c" /></span>}
                           </h2>
                           <p className="text-[14px] font-medium" style={{ color: theme.textSecondary }}>{selectedUserProfile.title}</p>
                           <div className="flex items-center gap-1 text-[12px] mt-1" style={{ color: theme.textTertiary }}>
                              <MapPin className="w-3 h-3" /> {selectedUserProfile.location}
                           </div>
                        </div>

                        <div className="flex justify-between items-center p-3 rounded-[16px] bg-[#146068]/5 border border-[#146068]/10">
                           <div className="text-center flex-1 border-r border-gray-500/10">
                              <div className="text-[16px] font-black text-[#146068]">{selectedUserProfile.jobSuccess}</div>
                              <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Job Success</div>
                           </div>
                           <div className="text-center flex-1 border-r border-gray-500/10">
                              <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.jobsCompleted}</div>
                              <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Total Jobs</div>
                           </div>
                           <div className="text-center flex-1">
                              <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.hourlyRate}</div>
                              <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Hourly</div>
                           </div>
                        </div>
                     </div>

                     {/* About */}
                     <div className="mb-6">
                        <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>About</h3>
                        <p className="text-[13px] leading-relaxed" style={{ color: theme.textSecondary }}>{selectedUserProfile.bio}</p>
                     </div>

                     {/* Skills */}
                     <div className="mb-6">
                        <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Skills</h3>
                        <div className="flex flex-wrap gap-2">
                           {selectedUserProfile.skills.map(skill => (
                              <span key={skill} className={`px-3 py-1.5 rounded-lg text-[11px] font-bold border ${theme.cardBorder} bg-white/5`} style={{ color: theme.text }}>
                                 {skill}
                              </span>
                           ))}
                        </div>
                     </div>

                     {/* Portfolio */}
                     <div className="mb-6">
                        <h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>
                           Portfolio <span className="text-[12px] font-normal opacity-60 text-[#146068]">View All</span>
                        </h3>
                        <div className="columns-2 gap-3 space-y-3">
                           {selectedUserProfile.portfolio.map(item => (
                              <div key={item.id} className="break-inside-avoid rounded-[16px] overflow-hidden relative group">
                                 <div className="w-full h-auto aspect-[4/5] bg-gray-200" style={{ backgroundColor: item.image }}></div>
                                 <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent opacity-100 flex flex-col justify-end p-3">
                                    <span className="text-[12px] font-bold text-white">{item.title}</span>
                                    <span className="text-[10px] text-white/70">{item.category}</span>
                                 </div>
                              </div>
                           ))}
                        </div>
                     </div>

                     {/* Reviews */}
                     <div className="mb-6">
                        <h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>
                           Reviews <span className="text-[12px] font-normal opacity-60">Recent</span>
                        </h3>
                        <div className="space-y-3">
                           {selectedUserProfile.reviews.map(review => (
                              <div key={review.id} className={`p-4 rounded-[16px] ${theme.cardBg} border ${theme.cardBorder}`}>
                                 <div className="flex justify-between items-start mb-2">
                                    <div className="flex items-center gap-2">
                                       <div className="w-8 h-8 rounded-full bg-[#93ccce] flex items-center justify-center text-[10px] font-black text-black">
                                          {review.clientInitials}
                                       </div>
                                       <div>
                                          <div className="text-[12px] font-bold" style={{ color: theme.text }}>{review.clientName}</div>
                                          <div className="flex text-[10px] text-[#f3bb19]">
                                             {[...Array(5)].map((_, i) => (
                                                <Star key={i} className={`w-3 h-3 ${i < review.rating ? "fill-[#f3bb19]" : "text-gray-400"}`} />
                                             ))}
                                          </div>
                                       </div>
                                    </div>
                                    <span className="text-[10px]" style={{ color: theme.textSecondary }}>{review.date}</span>
                                 </div>
                                 <p className="text-[12px] italic leading-relaxed" style={{ color: theme.textSecondary }}>"{review.comment}"</p>
                              </div>
                           ))}
                        </div>
                     </div>
                  </div>

                  {/* Sticky Footer Action */}
                  <div className={`absolute bottom-6 left-6 right-6 h-[60px] ${theme.bottomNavBg} backdrop-blur-2xl border ${theme.bottomNavBorder} rounded-[20px] flex items-center justify-between px-2 z-20 shadow-2xl`}>
                     <button className="flex-1 h-[46px] flex items-center justify-center gap-2 text-[14px] font-bold" style={{ color: theme.text }}>
                        <MessageSquare className="w-5 h-5" /> Message
                     </button>
                     <div className="w-[1px] h-[20px] bg-gray-500/20"></div>
                     <button className="flex-1 h-[46px] bg-[#146068] rounded-[16px] text-white font-bold text-[14px] shadow-lg hover:scale-[1.02] active:scale-95 transition-transform mx-1">
                        Hire Now
                     </button>
                  </div>
               </div>
            )}

            {/* Create Task Screen */}
             {showCreateTask && (
                <div className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
                   <div className={`px-6 pb-2 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-10`}>
                       <div className="flex justify-between items-center mb-4">
                          <button onClick={handleCloseCreateTask}><X className="w-5 h-5 text-[#146068]" /></button>
                          <h1 className="text-[20px] font-extrabold" style={{ color: theme.text }}>Create Task</h1>
                       </div>
                       <div className="w-full bg-[#146068]/10 h-1.5 rounded-full overflow-hidden mb-2">
                          <div className="h-full bg-[#146068] transition-all duration-500" style={{ width: `${(createStep/3)*100}%` }} />
                       </div>
                       <div className="flex justify-between text-[11px] font-bold" style={{ color: theme.textSecondary }}>
                          <span className={createStep >= 1 ? "text-[#146068]" : ""}>Concept</span>
                          <span className={createStep >= 2 ? "text-[#146068]" : ""}>Details</span>
                          <span className={createStep >= 3 ? "text-[#146068]" : ""}>Logistics</span>
                       </div>
                   </div>

                   <div className="flex-1 overflow-y-auto px-6 py-5 relative z-0">
                      {createStep === 1 && (
                         <div className="space-y-6 animate-fade-in">
                            <div>
                               <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Select Task Type</h3>
                               <div className="grid grid-cols-2 gap-3">
                                  <button onClick={() => setTaskForm({...taskForm, type: "Tender"})} className={`h-[100px] rounded-[18px] border-2 transition-all duration-300 hover:scale-[1.02] active:scale-95 ${taskForm.type === "Tender" ? "bg-[#f49d9d]/20 border-[#f49d9d]" : `${theme.cardBg} border-transparent`}`}>
                                     <div className="flex flex-col items-center justify-center gap-2">
                                        <span className="text-[28px]">📋</span>
                                        <span className="text-[14px] font-bold" style={{ color: taskForm.type === "Tender" ? "#f49d9d" : theme.text }}>Tender</span>
                                        <span className="text-[10px]" style={{ color: theme.textSecondary }}>Open proposals</span>
                                     </div>
                                  </button>
                                  <button onClick={() => setTaskForm({...taskForm, type: "Booking"})} className={`h-[100px] rounded-[18px] border-2 transition-all duration-300 hover:scale-[1.02] active:scale-95 ${taskForm.type === "Booking" ? "bg-[#146068]/20 border-[#146068]" : `${theme.cardBg} border-transparent`}`}>
                                     <div className="flex flex-col items-center justify-center gap-2">
                                        <span className="text-[28px]">📅</span>
                                        <span className="text-[14px] font-bold" style={{ color: taskForm.type === "Booking" ? "#146068" : theme.text }}>Booking</span>
                                        <span className="text-[10px]" style={{ color: theme.textSecondary }}>Direct hire</span>
                                     </div>
                                  </button>
                               </div>
                            </div>
                            <div>
                               <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Choose Category</h3>
                               <div className="grid grid-cols-3 gap-2.5">
                                  {popularCategories.map((cat, index) => (
                                     <button key={index} onClick={() => setTaskForm({...taskForm, category: cat.name.toLowerCase()})} className={`h-[80px] rounded-[16px] border-2 transition-all duration-300 active:scale-95 ${taskForm.category !== cat.name.toLowerCase() ? `${theme.cardBg} border-transparent` : ""}`} style={{ backgroundColor: taskForm.category === cat.name.toLowerCase() ? `${cat.color}20` : undefined, borderColor: taskForm.category === cat.name.toLowerCase() ? cat.color : undefined }}>
                                        <div className="flex flex-col items-center justify-center gap-1.5">
                                           <span className="text-[24px]">{cat.icon}</span>
                                           <span className="text-[11px] font-bold" style={{ color: theme.text }}>{cat.name}</span>
                                        </div>
                                     </button>
                                  ))}
                               </div>
                            </div>
                         </div>
                      )}

                      {createStep === 2 && (
                         <div className="space-y-6 animate-fade-in">
                            <div>
                               <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Title</label>
                               <input type="text" placeholder="e.g., Modern Logo Design" value={taskForm.title} onChange={(e) => setTaskForm({...taskForm, title: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} />
                            </div>
                            <div>
                               <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Description</label>
                               <textarea placeholder="Describe your project..." value={taskForm.description} onChange={(e) => setTaskForm({...taskForm, description: e.target.value})} rows={5} className={`w-full ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] p-4 outline-none resize-none focus:border-[#146068]`} style={{ color: theme.text }} />
                            </div>
                            <div>
                               <label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Tags</label>
                               <input type="text" placeholder="e.g., Design, Logo (comma separated)" value={taskForm.tags} onChange={(e) => setTaskForm({...taskForm, tags: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} />
                            </div>
                         </div>
                      )}

                      {createStep === 3 && (
                         <div className="space-y-6 animate-fade-in">
                            {taskForm.type === 'Booking' ? (
                               <>
                                  <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-2`}>
                                     {(['Basic', 'Standard', 'Premium'] as ServiceTier[]).map(tier => (
                                        <button key={tier} onClick={() => setActivePackageTab(tier)} className={`flex-1 py-2 rounded-[10px] text-[11px] font-bold transition-all duration-300 ${activePackageTab === tier ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}>{tier}</button>
                                     ))}
                                  </div>
                                  <div className="space-y-4">
                                     <div className="flex gap-3">
                                        <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Price ($)</label><input type="number" value={taskForm.packages[activePackageTab].price} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], price: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                        <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Delivery (Days)</label><input type="number" value={taskForm.packages[activePackageTab].deliveryTime} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], deliveryTime: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                        <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Revisions</label><input type="text" value={taskForm.packages[activePackageTab].revisions} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], revisions: e.target.value}}})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                     </div>
                                     <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Description</label><textarea value={taskForm.packages[activePackageTab].description} onChange={e => setTaskForm({...taskForm, packages: {...taskForm.packages, [activePackageTab]: {...taskForm.packages[activePackageTab], description: e.target.value}}})} className={`w-full h-[80px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} p-3 resize-none outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                  </div>
                               </>
                            ) : (
                               <>
                                  <div><label className="text-[13px] font-bold mb-2 block" style={{ color: theme.text }}>Budget ($)</label><input type="number" value={taskForm.budget} onChange={e => setTaskForm({...taskForm, budget: e.target.value})} className={`w-full h-[52px] ${theme.inputBg} border ${theme.inputBorder} rounded-[14px] px-4 outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                                  <div><label className="text-[13px] font-bold mb-3 block" style={{ color: theme.text }}>Deadline</label><div className="grid grid-cols-4 gap-2">{[{value:"3",label:"3 Days"},{value:"7",label:"1 Week"},{value:"14",label:"2 Weeks"},{value:"30",label:"1 Month"}].map(opt => (<button key={opt.value} onClick={() => setTaskForm({...taskForm, deadline: opt.value})} className={`h-[50px] rounded-[12px] border transition-all ${taskForm.deadline === opt.value ? "bg-[#146068]/20 border-[#146068] text-[#146068]" : `${theme.cardBg} border-transparent text-gray-500`}`}><span className="text-[12px] font-bold">{opt.label}</span></button>))}</div></div>
                               </>
                            )}
                            <div>
                               <label className="text-[13px] font-bold mb-3 block" style={{ color: theme.text }}>Experience Level</label>
                               <div className="grid grid-cols-3 gap-2">
                                  {['Entry', 'Intermediate', 'Expert'].map(level => (
                                     <button key={level} onClick={() => setTaskForm({...taskForm, experienceLevel: level as any})} className={`h-[50px] rounded-[12px] border transition-all ${taskForm.experienceLevel === level ? "bg-[#146068]/20 border-[#146068] text-[#146068]" : `${theme.cardBg} border-transparent text-gray-500`}`}>
                                        <span className="text-[12px] font-bold">{level}</span>
                                     </button>
                                  ))}
                               </div>
                            </div>
                         </div>
                      )}
                   </div>

                   <div className={`px-6 py-4 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} flex gap-3 z-10`}>
                      {createStep > 1 && <button onClick={() => setCreateStep(createStep - 1)} className={`w-[52px] h-[52px] rounded-[14px] ${theme.cardBg} border ${theme.cardBorder} flex items-center justify-center`}><ChevronLeft className="w-5 h-5" style={{ color: theme.text }} /></button>}
                      <button onClick={() => createStep < 3 ? setCreateStep(createStep + 1) : handleCloseCreateTask()} className="flex-1 h-[52px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:scale-[1.02] active:scale-95 transition-all shadow-xl flex items-center justify-center gap-2">
                         {createStep === 3 ? "Create Task" : "Next Step"}
                         {createStep < 3 && <ChevronRight className="w-5 h-5" />}
                      </button>
                   </div>
                </div>
             )}
          </>
        )}
      </div>
    </div>
  );
}