import React from "react";
import { X, Briefcase, DollarSign, FileText, AlertCircle } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { notifications } from "../Common/MockData";

interface NotificationCenterProps {
    onClose: () => void;
}

export const NotificationCenter: React.FC<NotificationCenterProps> = ({ onClose }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);

    return (
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex justify-end animate-fade-in" onClick={onClose}>
            <div className={`w-[85%] h-full ${theme.cardBg} border-l ${theme.cardBorder} backdrop-blur-2xl flex flex-col animate-slide-up`} onClick={e => e.stopPropagation()}>
                <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />
                <div className={`px-6 pt-12 pb-4 border-b ${theme.headerBorder} flex justify-between items-center relative z-10`}>
                    <h2 className="text-[20px] font-bold" style={{ color: theme.text }}>Notifications</h2>
                    <button onClick={onClose} className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10"><X className="w-5 h-5" style={{ color: theme.text }} /></button>
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
    );
};