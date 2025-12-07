
import React from 'react';
import { Task, Message, ProfileMenuItem, ProfileStat } from '../types';
import { FileText, Calendar, Heart, ArrowUpRight, User } from 'lucide-react';

interface ListViewProps {
  tasks?: Task[];
  messages?: Message[];
  profileStats?: ProfileStat[];
  profileMenuItems?: ProfileMenuItem[];
  theme: any;
  setSelectedTask?: (task: Task) => void;
  setSelectedChat?: (msg: Message) => void;
  setActiveNav?: (nav: any) => void;
  setIsDarkMode?: (val: boolean) => void;
  isDarkMode?: boolean;
  setIsLoggedIn?: (val: boolean) => void;
  toggleLike?: (id: number) => void;
  likedTasks?: Set<number>;
}

export const HomeList = ({ tasks, theme, setSelectedTask }: ListViewProps) => (
  <div className="space-y-4 pb-4">
    {tasks?.map((task) => (
      <div
        key={task.id}
        className={`${theme.cardBg} backdrop-blur-2xl rounded-[20px] overflow-hidden border ${theme.cardBorder} hover:${theme.cardBorderHover} hover:-translate-y-2 hover:scale-[1.02] active:scale-[0.98] transition-all duration-500 cursor-pointer`}
        onClick={() => setSelectedTask && setSelectedTask(task)}
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
);

export const TenderList = ({ tasks, theme, setSelectedTask }: ListViewProps) => (
  <div className="space-y-3">
    {tasks?.filter(t => t.type === 'Tender').map(task => (
      <div key={task.id} onClick={() => setSelectedTask && setSelectedTask(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
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
);

export const BookingList = ({ tasks, theme, setSelectedTask }: ListViewProps) => (
  <div className="space-y-3">
    {tasks?.filter(t => t.type === 'Booking').map(task => (
      <div key={task.id} onClick={() => setSelectedTask && setSelectedTask(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
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
);

export const MessagesList = ({ messages, theme, setSelectedChat }: ListViewProps) => (
  <div className="space-y-3 pb-4">
    {messages?.map((message) => (
      <div
        key={message.id}
        onClick={() => setSelectedChat && setSelectedChat(message)}
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
);

export const ProfileView = ({ profileStats, profileMenuItems, theme, setActiveNav, isDarkMode, setIsDarkMode, setIsLoggedIn }: ListViewProps) => {
    const renderIcon = (iconName: string, className: string) => {
        const iconMap: { [key: string]: React.ReactNode } = {
          User: <User className={className} strokeWidth={2} />,
          Heart: <Heart className={className} strokeWidth={2} />,
          Clock: <div className={className}>🕒</div>, // Fallback for simple
        };
        return iconMap[iconName] || <span className="text-[20px]">{iconName}</span>;
    };
    
    return (
      <>
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
               {profileStats?.map((stat, index) => (
                  <div key={index} className="rounded-[14px] p-3 text-center transition-colors duration-500" style={{ backgroundColor: isDarkMode ? "rgba(12, 12, 12, 0.2)" : "rgba(244, 243, 241, 0.5)" }}>
                     <div className="text-[20px] font-black tracking-tight leading-none mb-1" style={{ color: stat.color }}>{stat.value}</div>
                     <div className="text-[11px] font-semibold" style={{ color: theme.textSecondary }}>{stat.label}</div>
                  </div>
               ))}
            </div>
         </div>
         <div className="space-y-2.5 pb-4">
            {profileMenuItems?.map((item, index) => (
               <div 
                  key={index} 
                  onClick={() => { if (item.label === "Payments" && setActiveNav) setActiveNav("wallet"); }}
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
               <button onClick={() => setIsDarkMode && setIsDarkMode(!isDarkMode)} className={`relative w-14 h-7 rounded-full transition-all duration-300 flex-shrink-0 ${isDarkMode ? "bg-[#146068]" : "bg-[#9dbabb]"}`}><div className={`absolute top-0.5 w-6 h-6 rounded-full bg-[#f4f3f1] shadow-lg transition-all duration-300 ${isDarkMode ? "right-0.5" : "left-0.5"}`} /></button>
            </div>
         </div>
         <button onClick={() => setIsLoggedIn && setIsLoggedIn(false)} className="w-full bg-[#f49d9d]/10 border border-[#f49d9d]/30 rounded-[16px] p-4 text-[14px] font-bold text-[#f49d9d] hover:-translate-y-0.5 transition-all duration-300 active:scale-95">Logout</button>
      </>
    );
};
