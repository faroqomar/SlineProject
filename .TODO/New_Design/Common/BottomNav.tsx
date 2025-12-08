import React from 'react';
import { Home, FileText, Calendar, Briefcase, MessageCircle, User } from 'lucide-react';
import { NavView } from './types';

interface BottomNavProps {
  activeNav: NavView;
  setActiveNav: (nav: NavView) => void;
  isDarkMode: boolean;
  theme: any;
}

export default function BottomNav({ activeNav, setActiveNav, isDarkMode, theme }: BottomNavProps) {
  const navItems = [ 
    { id: "home", icon: Home }, 
    { id: "tender", icon: FileText }, 
    { id: "booking", icon: Calendar }, 
    { id: "orders", icon: Briefcase }, 
    { id: "messages", icon: MessageCircle, hasNotification: true }, 
    { id: "profile", icon: User } 
  ];

  return (
    <div className="absolute bottom-6 left-6 right-6 h-[80px] rounded-[30px] flex justify-around items-center px-1 z-40 transition-all duration-500 overflow-hidden backdrop-blur-xl animate-fade-in" 
         style={{ 
           background: isDarkMode ? "linear-gradient(to bottom, rgba(20, 96, 104, 0.2), rgba(0, 0, 0, 0.4))" : "linear-gradient(to bottom, rgba(255, 255, 255, 0.7), rgba(255, 255, 255, 0.4))", 
           boxShadow: isDarkMode ? "0 20px 40px -10px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.1), inset 0 -1px 0 rgba(0,0,0,0.2)" : "0 20px 40px -10px rgba(147, 204, 206, 0.4), inset 0 1px 0 rgba(255,255,255,0.8)", 
           border: isDarkMode ? "1px solid rgba(255,255,255,0.08)" : "1px solid rgba(255,255,255,0.6)", 
           backdropFilter: "blur(20px)" 
         }}>
      {navItems.map((item) => (
        <button key={item.id} onClick={() => setActiveNav(item.id as NavView)} className="flex flex-col items-center gap-1 px-2 py-2 rounded-2xl transition-all duration-300 relative group z-10 active:animate-spring">
           <item.icon className={`w-[22px] h-[22px] transition-all duration-300 drop-shadow-lg ${activeNav === item.id || (activeNav === "wallet" && item.id === "profile") ? "text-[#f4f3f1] scale-110" : "text-[#f4f3f1]/60"}`} strokeWidth={activeNav === item.id ? 2.5 : 2} />
           {item.hasNotification && <div className="absolute top-1 right-2 w-2 h-2 bg-[#f49d9d] rounded-full" />}
        </button>
      ))}
    </div>
  );
}