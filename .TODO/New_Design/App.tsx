import React, { useState } from "react";
import { Search, Filter, Bell, Plus } from "lucide-react";
import { 
  Task, Message, NavView, CategoryId, TaskFormState, ServiceTier,
  ChatMessage, Proposal, ProposalFormState, OrderStatus, FilterState, FreelancerProfile, ActiveCall
} from "./Common/types";
import { getTheme } from "./Common/Theme";
import * as Data from "./Common/Data";

// Components
import BottomNav from "./Common/BottomNav";

// Screens
import AuthScreen from "./Auth/AuthScreen";
import WalletScreen from "./Wallet/WalletScreen";
import OrdersScreen from "./Orders/OrdersScreen";
import HomeList from "./Home/HomeList";
import TenderList from "./Tenders/TenderList";
import BookingList from "./Bookings/BookingList";
import MessagesList from "./Messages/MessagesList";
import ProfileView from "./Profile/ProfileView";

// Modals
import TaskDetailsModal from "./TaskDetails/TaskDetailsModal";
import ChatModal from "./Messages/ChatModal";
import VideoCallModal from "./Messages/VideoCallModal";
import CreateTaskModal from "./CreateTask/CreateTaskModal";
import NotificationsModal from "./Notifications/NotificationsModal";
import FiltersModal from "./Filters/FiltersModal";
import PublicProfileModal from "./PublicProfile/PublicProfileModal";
import ProposalSubmitModal from "./ProposalDetails/ProposalSubmitModal";
import ProposalDetailsModal from "./ProposalDetails/ProposalDetailsModal";

export default function App() {
  const [likedTasks, setLikedTasks] = useState<Set<number>>(new Set([1]));
  const [activeNav, setActiveNav] = useState<NavView>("home");
  const [activeCategory, setActiveCategory] = useState<CategoryId>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [selectedChat, setSelectedChat] = useState<Message | null>(null);
  const [selectedProposal, setSelectedProposal] = useState<Proposal | null>(null);
  const [selectedUserProfile, setSelectedUserProfile] = useState<FreelancerProfile | null>(null);
  
  const [activeOrderTab, setActiveOrderTab] = useState<OrderStatus>("Active");
  const [selectedPackageTier, setSelectedPackageTier] = useState<ServiceTier>("Basic");
  const [activePackageTab, setActivePackageTab] = useState<ServiceTier>("Basic");

  const [showOfferModal, setShowOfferModal] = useState(false);
  const [offerForm, setOfferForm] = useState({ title: '', description: '', price: '', deliveryTime: '3' });

  const [showProposalModal, setShowProposalModal] = useState(false);
  const [proposalForm, setProposalForm] = useState<ProposalFormState>({ bidAmount: '', deliveryTime: '3 Days', coverLetter: '' });
  
  const [showNotifications, setShowNotifications] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [filters, setFilters] = useState<FilterState>({ minBudget: '', maxBudget: '', deliveryTime: [], sellerLevel: [], sortBy: 'Relevance' });

  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [authScreen, setAuthScreen] = useState<"login" | "signup">("login");
  const [isDarkMode, setIsDarkMode] = useState(true);
  const [showCreateTask, setShowCreateTask] = useState(false);
  const [createStep, setCreateStep] = useState(1);
  const [taskForm, setTaskForm] = useState<TaskFormState>({
    title: "", description: "", category: "design", budget: "", type: "Tender", tags: "", deadline: "7", experienceLevel: "Intermediate",
    packages: {
      Basic: { price: "", deliveryTime: "3", description: "", revisions: "1" },
      Standard: { price: "", deliveryTime: "7", description: "", revisions: "2" },
      Premium: { price: "", deliveryTime: "14", description: "", revisions: "Unlimited" }
    }
  });

  const [activeCall, setActiveCall] = useState<ActiveCall | null>(null);

  const theme = getTheme(isDarkMode);

  const toggleLike = (taskId: number) => {
    const newLiked = new Set(likedTasks);
    if (newLiked.has(taskId)) newLiked.delete(taskId);
    else newLiked.add(taskId);
    setLikedTasks(newLiked);
  };

  const handleCloseCreateTask = () => {
    setShowCreateTask(false);
    setTimeout(() => setCreateStep(1), 300);
  };

  const handleSubmitProposal = () => {
    console.log("Submitting proposal:", proposalForm);
    setShowProposalModal(false);
  };

  const handleSendOffer = () => {
    if (!selectedChat) return;
    const newOfferMsg: ChatMessage = {
      id: Date.now(), text: "", sender: 'me', time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      type: 'offer', offer: { title: offerForm.title, description: offerForm.description, price: `$${offerForm.price}`, deliveryTime: `${offerForm.deliveryTime} Days`, status: 'pending' }
    };
    const updatedChat = { ...selectedChat, history: [...(selectedChat.history || []), newOfferMsg] };
    setSelectedChat(updatedChat);
    setShowOfferModal(false);
    setOfferForm({ title: '', description: '', price: '', deliveryTime: '3' });
  };
  
  const toggleFilter = (type: 'deliveryTime' | 'sellerLevel', value: string) => {
    const current = filters[type];
    const newValues = current.includes(value) ? current.filter(i => i !== value) : [...current, value];
    setFilters({...filters, [type]: newValues});
  };

  const handleStartVideoCall = () => {
    if (!selectedChat) return;
    setActiveCall({
      id: 1,
      name: selectedChat.name,
      avatar: selectedChat.initials,
      status: 'calling',
      isMuted: false,
      isVideoOn: true
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#146068] via-[#93ccce] to-[#f7d69c] flex items-center justify-center p-5">
      <div className="w-full max-w-[390px] h-[844px] rounded-[50px] shadow-2xl relative overflow-hidden flex flex-col transition-colors duration-500"
        style={{ backgroundColor: theme.phoneBg, boxShadow: isDarkMode ? "0 0 0 1px rgba(255,255,255,0.1), 0 30px 60px -10px rgba(0,0,0,0.5)" : "0 0 0 1px rgba(0,0,0,0.05), 0 30px 60px -10px rgba(0,0,0,0.2)" }}
      >
        <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />

        {!isLoggedIn ? (
          <AuthScreen authScreen={authScreen} setAuthScreen={setAuthScreen} setIsLoggedIn={setIsLoggedIn} theme={theme} />
        ) : (
          <>
            <div className="flex-1 flex flex-col overflow-hidden relative animate-fade-in z-10">
              {/* HEADER */}
              <div className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}>
                  {activeNav === "home" ? (
                    <>
                      <div className="flex justify-between items-center mb-6">
                          <div className="flex items-center gap-3">
                              <div className="w-[52px] h-[52px] rounded-[18px] bg-[#f3bb19] border-2 border-[#f4f3f1]/20 overflow-hidden relative shadow-lg">
                                  <img src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=256&q=80" className="w-full h-full object-cover" alt="User" />
                              </div>
                              <div>
                                  <p className="text-[13px] font-medium mb-0.5" style={{ color: theme.textSecondary }}>Good Morning 👋</p>
                                  <h1 className="text-[20px] font-extrabold leading-none tracking-tight" style={{ color: theme.text }}>Sarah Miller</h1>
                              </div>
                          </div>
                          <button onClick={() => setShowNotifications(true)} className={`w-[46px] h-[46px] rounded-[16px] ${theme.cardBg} border ${theme.cardBorder} flex items-center justify-center relative hover:scale-[1.05] active:scale-95 transition-all shadow-sm`}>
                              <Bell className="w-5 h-5" style={{ color: theme.text }} />
                              <span className="absolute top-3.5 right-3.5 w-2 h-2 bg-[#f49d9d] rounded-full border-2" style={{ borderColor: theme.phoneBg }} />
                          </button>
                      </div>
                      <div className="relative mb-3">
                        <Search className="absolute left-[16px] top-1/2 -translate-y-1/2 w-4 h-4" style={{ color: theme.textSecondary }} strokeWidth={2.5} />
                        <input type="text" placeholder="Search amazing projects..." className={`w-full h-[48px] ${theme.inputBg} backdrop-blur-lg border-[1.5px] ${theme.inputBorder} rounded-[16px] pl-[44px] pr-[56px] text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`} style={{ color: theme.text }} value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
                        <button onClick={() => setShowFilters(true)} className="absolute right-1.5 top-1/2 -translate-y-1/2 bg-[#146068] rounded-[12px] w-[38px] h-[38px] flex items-center justify-center hover:scale-110 transition-transform shadow-lg active:scale-90"><Filter className="w-4 h-4 text-[#f4f3f1]" strokeWidth={2.5} /></button>
                      </div>
                      <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}>
                        {Data.categories.map((cat) => (
                          <button key={cat.id} onClick={() => setActiveCategory(cat.id)} className={`px-4 py-2 rounded-[12px] text-[13px] font-semibold whitespace-nowrap transition-all duration-300 active:scale-95 ${activeCategory === cat.id ? "bg-[#146068] text-[#f4f3f1] shadow-lg" : `${theme.inputBg} backdrop-blur-lg border ${theme.inputBorder} hover:bg-[#f4f3f1]/15`}`} style={activeCategory !== cat.id ? { color: theme.text } : {}}>{cat.label}</button>
                        ))}
                      </div>
                    </>
                  ) : (
                    // Logic for other headers (simplified for brevity based on activeNav)
                    <div className="flex justify-between items-center mb-2">
                       <div>
                          <h1 className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none" style={{ color: theme.text }}>
                             {activeNav === 'tender' ? 'Tenders' : activeNav === 'booking' ? 'Bookings' : activeNav === 'messages' ? 'Messages' : activeNav === 'orders' ? 'My Orders' : activeNav === 'wallet' ? 'My Wallet' : 'Profile'}
                          </h1>
                          <p className="text-[13px] font-medium" style={{ color: theme.textSecondary }}>
                             {activeNav === 'tender' ? 'Open proposals' : activeNav === 'booking' ? 'Direct hire opportunities' : activeNav === 'messages' ? '4 unread conversations' : activeNav === 'orders' ? 'Track your active jobs' : activeNav === 'wallet' ? 'Manage your earnings' : 'Manage your account'}
                          </p>
                       </div>
                    </div>
                  )}
                  {activeNav === 'orders' && (
                     <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-2`}>
                        {(["Active", "Revision", "Completed", "Cancelled"] as OrderStatus[]).map(status => (
                           <button key={status} onClick={() => setActiveOrderTab(status)} className={`flex-1 py-2 rounded-[10px] text-[11px] font-bold transition-all duration-300 ${activeOrderTab === status ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}>{status}</button>
                        ))}
                     </div>
                  )}
              </div>

              {/* MAIN CONTENT AREA */}
              <div className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`} style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
                   {activeNav === "home" && <HomeList tasks={Data.tasks} theme={theme} setSelectedTask={setSelectedTask} />}
                   {activeNav === "tender" && <TenderList tasks={Data.tasks} theme={theme} setSelectedTask={setSelectedTask} />}
                   {activeNav === "booking" && <BookingList tasks={Data.tasks} theme={theme} setSelectedTask={setSelectedTask} />}
                   {activeNav === "messages" && <MessagesList messages={Data.messages} theme={theme} setSelectedChat={setSelectedChat} />}
                   {activeNav === "orders" && <OrdersScreen orders={Data.orders} activeOrderTab={activeOrderTab} theme={theme} />}
                   {activeNav === "wallet" && <WalletScreen walletData={Data.walletData} theme={theme} />}
                   {activeNav === "profile" && <ProfileView profileStats={Data.profileStats} profileMenuItems={Data.profileMenuItems} theme={theme} setActiveNav={setActiveNav} isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode} setIsLoggedIn={setIsLoggedIn} />}
              </div>

              {/* BOTTOM NAV */}
              <BottomNav activeNav={activeNav} setActiveNav={setActiveNav} isDarkMode={isDarkMode} theme={theme} />
              <button onClick={() => setShowCreateTask(true)} className="absolute bottom-[100px] right-6 w-14 h-14 rounded-[18px] bg-[#146068] shadow-2xl flex items-center justify-center hover:scale-110 active:scale-90 hover:rotate-90 transition-all duration-400 z-30">
                <Plus className="w-7 h-7 text-[#f4f3f1]" strokeWidth={3} />
              </button>
            </div>

            {/* MODALS AND OVERLAYS */}
            {showNotifications && <NotificationsModal theme={theme} setShowNotifications={setShowNotifications} notifications={Data.notifications} />}
            {showFilters && <FiltersModal theme={theme} setShowFilters={setShowFilters} filters={filters} setFilters={setFilters} toggleFilter={toggleFilter} />}
            {showCreateTask && <CreateTaskModal theme={theme} handleCloseCreateTask={handleCloseCreateTask} createStep={createStep} setCreateStep={setCreateStep} taskForm={taskForm} setTaskForm={setTaskForm} popularCategories={Data.popularCategories} activePackageTab={activePackageTab} setActivePackageTab={setActivePackageTab} />}
            
            {selectedChat && <ChatModal selectedChat={selectedChat} theme={theme} setSelectedChat={setSelectedChat} showOfferModal={showOfferModal} setShowOfferModal={setShowOfferModal} offerForm={offerForm} setOfferForm={setOfferForm} handleSendOffer={handleSendOffer} handleStartVideoCall={handleStartVideoCall} />}
            
            {activeCall && <VideoCallModal theme={theme} activeCall={activeCall} setActiveCall={setActiveCall} />}

            {selectedTask && !selectedProposal && (
              <TaskDetailsModal 
                 selectedTask={selectedTask} theme={theme} setSelectedTask={setSelectedTask} 
                 selectedPackageTier={selectedPackageTier} setSelectedPackageTier={setSelectedPackageTier} 
                 setSelectedUserProfile={setSelectedUserProfile} mockFreelancerProfile={Data.mockFreelancerProfile}
                 setSelectedProposal={setSelectedProposal} setShowProposalModal={setShowProposalModal}
              />
            )}

            {showProposalModal && selectedTask && (
               <ProposalSubmitModal theme={theme} setShowProposalModal={setShowProposalModal} proposalForm={proposalForm} setProposalForm={setProposalForm} handleSubmitProposal={handleSubmitProposal} budget={selectedTask.budget} />
            )}

            {selectedProposal && !selectedUserProfile && (
               <ProposalDetailsModal theme={theme} selectedProposal={selectedProposal} setSelectedProposal={setSelectedProposal} setSelectedUserProfile={setSelectedUserProfile} mockFreelancerProfile={Data.mockFreelancerProfile} />
            )}

            {selectedUserProfile && (
               <PublicProfileModal theme={theme} selectedUserProfile={selectedUserProfile} setSelectedUserProfile={setSelectedUserProfile} />
            )}
          </>
        )}
      </div>
    </div>
  );
}