import React, { useState } from "react";
import {
  Home,
  MessageCircle,
  User,
  FileText,
  Calendar,
  Briefcase,
  Plus
} from "lucide-react";
import { 
  Task, 
  Message, 
  NavView, 
  ServiceTier,
  Proposal,
  FilterState,
  FreelancerProfile,
  CategoryId,
  TaskFormState,
  ProposalFormState
} from "./Common/types";
import { getTheme } from "./Common/Theme";

// Import Modular Components
import { AuthScreens } from "./Auth/AuthScreens";
import { HomeView } from "./Home/HomeView";
import { TenderListView } from "./Tenders/TenderListView";
import { BookingListView } from "./Bookings/BookingListView";
import { MessagesListView } from "./Messages/MessagesListView";
import { OrdersDashboard } from "./Orders/OrdersDashboard";
import { WalletDashboard } from "./Wallet/WalletDashboard";
import { ProfileView } from "./Profile/ProfileView";
import { NotificationCenter } from "./Notifications/NotificationCenter";
import { AdvancedFilters } from "./Filters/AdvancedFilters";
import { ChatOverlay } from "./Messages/ChatOverlay";
import { TaskDetailsOverlay } from "./TaskDetails/TaskDetailsOverlay";
import { ProposalDetailsOverlay } from "./ProposalDetails/ProposalDetailsOverlay";
import { PublicProfileOverlay } from "./PublicProfile/PublicProfileOverlay";
import { CreateTaskOverlay } from "./CreateTask/CreateTaskOverlay";

export default function App() {
  // Main State
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [activeNav, setActiveNav] = useState<NavView>("home");
  const [isDarkMode, setIsDarkMode] = useState(true);
  const theme = getTheme(isDarkMode);

  // Feature States
  const [showNotifications, setShowNotifications] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [showCreateTask, setShowCreateTask] = useState(false);
  
  // Selection States
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [selectedChat, setSelectedChat] = useState<Message | null>(null);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const [selectedUserProfile, setSelectedUserProfile] = useState<FreelancerProfile | null>(null);
  
  // Task/Booking States
  const [selectedPackageTier, setSelectedPackageTier] = useState<ServiceTier>("Basic");

  // Forms & Filter States (lifted up if needed by multiple components, or passed down)
  const [filters, setFilters] = useState<FilterState>({
    minBudget: '',
    maxBudget: '',
    deliveryTime: [],
    sellerLevel: [],
    sortBy: 'Relevance'
  });

  // Render Content based on Active Nav
  const renderContent = () => {
    switch (activeNav) {
      case "home":
        return <HomeView 
          onTaskSelect={setSelectedTask} 
          onShowNotifications={() => setShowNotifications(true)}
          onShowFilters={() => setShowFilters(true)}
        />;
      case "tender":
        return <TenderListView onTaskSelect={setSelectedTask} />;
      case "booking":
        return <BookingListView onTaskSelect={setSelectedTask} />;
      case "messages":
        return <MessagesListView onChatSelect={setSelectedChat} />;
      case "orders":
        return <OrdersDashboard />;
      case "wallet":
        return <WalletDashboard />;
      case "profile":
        return <ProfileView 
            onLogout={() => setIsLoggedIn(false)} 
            onNavigate={(nav) => setActiveNav(nav as NavView)}
            isDarkMode={isDarkMode}
            toggleTheme={() => setIsDarkMode(!isDarkMode)}
        />;
      default:
        return <HomeView 
            onTaskSelect={setSelectedTask} 
            onShowNotifications={() => setShowNotifications(true)}
            onShowFilters={() => setShowFilters(true)}
        />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#146068] via-[#93ccce] to-[#f7d69c] flex items-center justify-center p-5">
      {/* Phone Mockup */}
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
          <AuthScreens onLogin={() => setIsLoggedIn(true)} />
        ) : (
          <>
            {/* Main Content Area */}
            {renderContent()}

            {/* FAB & Bottom Nav */}
            <button 
                onClick={() => setShowCreateTask(true)} 
                className="absolute bottom-[100px] right-6 w-14 h-14 rounded-[18px] bg-[#146068] shadow-2xl flex items-center justify-center hover:scale-110 active:scale-90 hover:rotate-90 transition-all duration-400 z-30"
            >
                <Plus className="w-7 h-7 text-[#f4f3f1]" strokeWidth={3} />
            </button>
            
            <div 
                className="absolute bottom-6 left-6 right-6 h-[80px] rounded-[30px] flex justify-around items-center px-1 z-40 transition-all duration-500 overflow-hidden backdrop-blur-xl animate-fade-in" 
                style={{ 
                    background: isDarkMode ? "linear-gradient(to bottom, rgba(20, 96, 104, 0.2), rgba(0, 0, 0, 0.4))" : "linear-gradient(to bottom, rgba(255, 255, 255, 0.7), rgba(255, 255, 255, 0.4))", 
                    boxShadow: isDarkMode ? "0 20px 40px -10px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1), inset 0 -1px 0 rgba(0,0,0,0.2)" : "0 20px 40px -10px rgba(147, 204, 206, 0.4), inset 0 1px 0 rgba(255,255,255,0.8)", 
                    border: isDarkMode ? "1px solid rgba(255,255,255,0.08)" : "1px solid rgba(255,255,255,0.6)", 
                    backdropFilter: "blur(20px)" 
                }}
            >
                {[ 
                { id: "home", icon: Home }, 
                { id: "tender", icon: FileText }, 
                { id: "booking", icon: Calendar }, 
                { id: "orders", icon: Briefcase }, 
                { id: "messages", icon: MessageCircle, hasNotification: true }, 
                { id: "profile", icon: User } 
                ].map((item) => (
                <button 
                    key={item.id} 
                    onClick={() => setActiveNav(item.id as NavView)} 
                    className="flex flex-col items-center gap-1 px-2 py-2 rounded-2xl transition-all duration-300 relative group z-10 active:animate-spring"
                >
                    <item.icon 
                        className={`w-[22px] h-[22px] transition-all duration-300 drop-shadow-lg ${activeNav === item.id || (activeNav === "wallet" && item.id === "profile") ? "text-[#f4f3f1] scale-110" : "text-[#f4f3f1]/60"}`} 
                        strokeWidth={activeNav === item.id ? 2.5 : 2} 
                    />
                    {item.hasNotification && <div className="absolute top-1 right-2 w-2 h-2 bg-[#f49d9d] rounded-full" />}
                </button>
                ))}
            </div>

            {/* Overlays */}
            {showNotifications && (
                <NotificationCenter onClose={() => setShowNotifications(false)} />
            )}
            
            {showFilters && (
                <AdvancedFilters 
                    isVisible={showFilters} 
                    onClose={() => setShowFilters(false)}
                    filters={filters}
                    setFilters={setFilters}
                />
            )}

            {selectedChat && (
                <ChatOverlay 
                    selectedChat={selectedChat} 
                    onClose={() => setSelectedChat(null)} 
                />
            )}

            {selectedTask && !selectedProposal && (
                <TaskDetailsOverlay
                    selectedTask={selectedTask}
                    onClose={() => { setSelectedTask(null); setSelectedPackageTier('Basic'); }}
                    selectedPackageTier={selectedPackageTier}
                    setSelectedPackageTier={setSelectedPackageTier}
                    onShowProposalModal={() => {}} // Handle internal logic if needed or pass handler
                    setShowProposalModal={() => {}} // Placeholder or manage state here if needed
                    onSelectProposal={setSelectedProposal}
                    onSelectProfile={setSelectedUserProfile}
                />
            )}

            {selectedProposal && !selectedUserProfile && (
                <ProposalDetailsOverlay
                    proposal={selectedProposal}
                    onClose={() => setSelectedProposal(null)}
                    onViewProfile={setSelectedUserProfile}
                />
            )}

            {selectedUserProfile && (
                <PublicProfileOverlay
                    profile={selectedUserProfile}
                    onClose={() => setSelectedUserProfile(null)}
                />
            )}

            {showCreateTask && (
                <CreateTaskOverlay onClose={() => setShowCreateTask(false)} />
            )}

          </>
        )}
      </div>
    </div>
  );
}