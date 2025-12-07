import React from "react";
import { Filter } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { messages } from "../Common/MockData";
import { Message } from "../Common/types";

interface MessagesListViewProps {
    onChatSelect: (message: Message) => void;
}

export const MessagesListView: React.FC<MessagesListViewProps> = ({ onChatSelect }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);

    return (
        <div className="flex-1 flex flex-col h-full">
            <div className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}>
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
            </div>

            <div
                className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                scrollbarWidth: "thin",
                scrollbarColor: theme.scrollbarColor,
                }}
            >
                <div className="space-y-3 pb-4">
                    {messages.map((message) => (
                        <div
                            key={message.id}
                            onClick={() => onChatSelect(message)}
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
            </div>
        </div>
    );
};