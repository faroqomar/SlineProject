
import { Category, PopularCategory, Notification, FreelancerProfile, Order, WalletData, Message, ProfileStat, ProfileMenuItem, Task } from "./types";

export const categories: Category[] = [
  { id: "all", label: "✨ All" },
  { id: "design", label: "🎨 Design" },
  { id: "dev", label: "💻 Dev" },
  { id: "writing", label: "✍️ Writing" },
  { id: "mobile", label: "📱 Mobile" },
  { id: "marketing", label: "🎯 Marketing" },
];

export const popularCategories: PopularCategory[] = [
  { icon: "🎨", name: "Design", color: "#f49d9d" },
  { icon: "💻", name: "Development", color: "#93ccce" },
  { icon: "✍️", name: "Writing", color: "#f7d69c" },
  { icon: "📱", name: "Mobile", color: "#f3bb19" },
  { icon: "🎯", name: "Marketing", color: "#9dbabb" },
  { icon: "🎬", name: "Video", color: "#146068" },
];

export const notifications: Notification[] = [
  { id: 1, type: 'order', title: 'Order Update', message: 'Nexus Corp marked your order as Completed.', time: '2m ago', isRead: false, group: 'Today' },
  { id: 2, type: 'proposal', title: 'New Proposal', message: 'David Chen applied to your Logo Design job.', time: '1h ago', isRead: false, group: 'Today' },
  { id: 3, type: 'system', title: 'System Alert', message: 'Your password was changed successfully.', time: '3h ago', isRead: true, group: 'Today' },
  { id: 4, type: 'payment', title: 'Payment Received', message: 'You received $250.00 from TravelLife.', time: 'Yesterday', isRead: true, group: 'Yesterday' },
  { id: 5, type: 'proposal', title: 'Proposal Accepted', message: 'Your proposal for React Dashboard was accepted!', time: 'Yesterday', isRead: true, group: 'Yesterday' },
];

export const mockFreelancerProfile: FreelancerProfile = {
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

export const orders: Order[] = [
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

export const walletData: WalletData = {
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

export const messages: Message[] = [
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

export const profileStats: ProfileStat[] = [
  { label: "Projects", value: "47", color: "#146068" },
  { label: "Rating", value: "4.9", color: "#f3bb19" },
  { label: "Earned", value: "$12.5k", color: "#93ccce" },
];

export const profileMenuItems: ProfileMenuItem[] = [
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

export const tasks: Task[] = [
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
