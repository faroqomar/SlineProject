import React from 'react';
import { Message } from '../Common/types';

interface MessagesListProps {
  messages: Message[];
  theme: any;
  setSelectedChat: (msg: Message) => void;
}

export default function MessagesList({ messages, theme, setSelectedChat }: MessagesListProps) {
  return (
    <div className="space-y-3 pb-4">
      {messages?.map((message) => (
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
  );
}