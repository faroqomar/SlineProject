
export type NavView = "home" | "tender" | "booking" | "messages" | "profile" | "orders" | "wallet";
export type AuthView = "login" | "signup";
export type CategoryId = "all" | "design" | "dev" | "writing" | "mobile" | "marketing";
export type ServiceTier = "Basic" | "Standard" | "Premium";
export type OrderStatus = "Active" | "Revision" | "Completed" | "Cancelled";
export type TransactionType = "deposit" | "withdrawal" | "payment" | "fee" | "escrow";
export type TransactionStatus = "completed" | "pending" | "failed";

export interface TaskAuthor {
  name: string;
  initials: string;
  verified: boolean;
  time: string;
}

export interface ServicePackage {
  tier: ServiceTier;
  price: string;
  deliveryTime: string;
  description: string;
  revisions: string;
}

export interface PortfolioItem {
  id: number;
  image: string; // URL or placeholder color
  title: string;
  category: string;
}

export interface Review {
  id: number;
  clientName: string;
  clientInitials: string;
  rating: number;
  comment: string;
  date: string;
}

export interface FreelancerProfile {
  id: number;
  name: string;
  initials: string;
  title: string;
  bio: string;
  location: string;
  rating: string;
  jobsCompleted: number;
  hourlyRate: string;
  jobSuccess: string;
  skills: string[];
  portfolio: PortfolioItem[];
  reviews: Review[];
  verified: boolean;
  online: boolean;
}

export interface Proposal {
  id: number;
  freelancer: {
    name: string;
    initials: string;
    rating: string;
    verified: boolean;
    location: string;
    online: boolean;
  };
  bidAmount: string;
  deliveryTime: string;
  coverLetter: string;
  attachments: string[];
  submittedAt: string;
}

export interface Order {
  id: number;
  title: string;
  client: {
    name: string;
    initials: string;
  };
  price: string;
  dueDate: string; // ISO string or relative text for mock
  status: OrderStatus;
  type: "Tender" | "Booking";
  timeLeft?: string; // For the countdown display
}

export interface Transaction {
  id: number;
  type: TransactionType;
  description: string;
  amount: string;
  date: string;
  status: TransactionStatus;
  isPositive: boolean;
  referenceId?: string;
}

export interface WalletData {
  totalBalance: string;
  availableBalance: string;
  escrowBalance: string;
  currency: string;
  cardLast4: string;
  transactions: Transaction[];
}

export interface Task {
  id: number;
  type: "Tender" | "Booking";
  isHot: boolean;
  bgColor: string;
  author: TaskAuthor;
  title: string;
  description: string;
  tags: string[];
  timeLeft: string;
  offers: number | null;
  budget: string;
  packages?: ServicePackage[];
  proposals?: Proposal[];
}

export interface ChatOffer {
  price: string;
  title: string;
  description: string;
  deliveryTime?: string;
  status: 'pending' | 'accepted' | 'declined';
}

export interface ChatMessage {
  id: number;
  text: string;
  sender: 'me' | 'them';
  time: string;
  type: 'text' | 'offer';
  offer?: ChatOffer;
}

export interface Message {
  id: number;
  name: string;
  initials: string;
  lastMessage: string;
  time: string;
  unread: number;
  online: boolean;
  verified: boolean;
  history?: ChatMessage[];
}

export interface Category {
  id: CategoryId;
  label: string;
  description?: string;
}

export interface ProfileStat {
  label: string;
  value: string;
  color: string;
}

export interface ProfileMenuItem {
  icon: string;
  label: string;
  description: string;
  color: string;
  badge: string | null;
}

export interface PackageFormState {
  price: string;
  deliveryTime: string;
  description: string;
  revisions: string;
}

export interface TaskFormState {
  title: string;
  description: string;
  category: string;
  budget: string;
  type: string;
  tags: string;
  deadline: string;
  experienceLevel: "Entry" | "Intermediate" | "Expert";
  packages: {
    Basic: PackageFormState;
    Standard: PackageFormState;
    Premium: PackageFormState;
  };
}

export interface PopularCategory {
  icon: string;
  name: string;
  color: string;
}
export interface ProposalFormState {
  bidAmount: string;
  deliveryTime: string;
  coverLetter: string;
}

export interface Notification {
  id: number;
  type: 'system' | 'order' | 'proposal' | 'payment';
  title: string;
  message: string;
  time: string;
  isRead: boolean;
  group: 'Today' | 'Yesterday';
}

export interface FilterState {
  minBudget: string;
  maxBudget: string;
  deliveryTime: string[];
  sellerLevel: string[];
  sortBy: string;
}