import React from 'react';
import { User, Heart, ArrowUpRight } from 'lucide-react';
import { ProfileStat, ProfileMenuItem } from '../Common/types';

interface ProfileViewProps {
  profileStats: ProfileStat[];
  profileMenuItems: ProfileMenuItem[];
  theme: any;
  setActiveNav: (nav: any) => void;
  isDarkMode: boolean;
  setIsDarkMode: (val: boolean) => void;
  setIsLoggedIn: (val: boolean) => void;
}

export default function ProfileView({ profileStats, profileMenuItems, theme, setActiveNav, isDarkMode, setIsDarkMode, setIsLoggedIn }: ProfileViewProps) {
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
}