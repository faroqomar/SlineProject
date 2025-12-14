import React from 'react';
import { ChevronLeft, DollarSign, Clock, Paperclip, Send, Video } from 'lucide-react';
import { Message, ChatMessage } from '../Common/types';

interface ChatModalProps {
  selectedChat: Message;
  theme: any;
  setSelectedChat: (m: Message | null) => void;
  showOfferModal: boolean;
  setShowOfferModal: (v: boolean) => void;
  offerForm: any;
  setOfferForm: (f: any) => void;
  handleSendOffer: () => void;
  handleStartVideoCall: () => void;
}

export default function ChatModal({
  selectedChat, theme, setSelectedChat, showOfferModal, setShowOfferModal, offerForm, setOfferForm, handleSendOffer, handleStartVideoCall
}: ChatModalProps) {
  return (
    <div className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 animate-slide-up overflow-hidden" style={{ backgroundColor: theme.phoneBg }}>
       <div className={`px-4 pt-8 pb-3 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-20`}>
          <div className="flex items-center gap-2">
             <button onClick={() => setSelectedChat(null)} className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95"><ChevronLeft className="w-6 h-6" style={{ color: theme.text }} /></button>
             <h2 className="text-[15px] font-bold">{selectedChat.name}</h2>
          </div>
          <div className="flex gap-2">
             <button onClick={handleStartVideoCall} className="w-10 h-10 rounded-full bg-[#146068]/10 flex items-center justify-center text-[#146068] hover:bg-[#146068]/20 transition-colors active:scale-95"><Video className="w-5 h-5" /></button>
             <button onClick={() => setShowOfferModal(true)} className="flex items-center gap-1 bg-[#146068] px-3 py-1.5 rounded-full text-white active:scale-95 transition-transform"><DollarSign className="w-4 h-4" /><span className="text-[11px] font-bold">Offer</span></button>
          </div>
       </div>
       <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 relative z-10">
          {selectedChat.history?.map((msg) => (
             <div key={msg.id} className={`flex flex-col ${msg.sender === 'me' ? 'items-end' : 'items-start'}`}>
                {msg.type === 'offer' && msg.offer ? (
                   <div className="max-w-[85%] bg-[#146068]/10 border border-[#146068]/30 backdrop-blur-md rounded-[20px] p-4 mb-1">
                      <div className="flex justify-between items-start mb-2">
                         <div className="bg-[#146068] text-white text-[10px] font-bold px-2 py-0.5 rounded-md uppercase">Custom Offer</div>
                         <div className="text-[#146068] font-black text-[16px]">{msg.offer.price}</div>
                      </div>
                      <h3 className="text-[14px] font-bold mb-1" style={{ color: theme.text }}>{msg.offer.title}</h3>
                      <p className="text-[12px] mb-3 leading-relaxed" style={{ color: theme.textSecondary }}>{msg.offer.description}</p>
                      <div className="flex items-center gap-1 text-[11px] font-medium mb-3" style={{ color: theme.textSecondary }}><Clock className="w-3 h-3" /> {msg.offer.deliveryTime} Delivery</div>
                      <div className="flex gap-2">
                         <button className="flex-1 bg-[#146068] text-white h-[36px] rounded-[10px] text-[12px] font-bold hover:scale-[1.02] active:scale-95 transition-transform">Accept</button>
                         <button className="flex-1 bg-transparent border border-[#146068]/30 h-[36px] rounded-[10px] text-[12px] font-bold hover:bg-[#146068]/5 active:scale-95 transition-all" style={{ color: theme.text }}>Decline</button>
                      </div>
                   </div>
                ) : (
                   <div className={`max-w-[80%] px-4 py-2.5 rounded-[18px] text-[14px] leading-relaxed ${msg.sender === 'me' ? 'bg-[#146068] text-white' : `${theme.cardBg} border ${theme.cardBorder}`}`} style={msg.sender === 'them' ? { color: theme.text } : {}}>{msg.text}</div>
                )}
                <span className="text-[10px] mt-1 px-1 opacity-60" style={{ color: theme.textSecondary }}>{msg.time}</span>
             </div>
          ))}
       </div>
        <div className={`px-4 py-3 pb-8 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-20`}>
           <div className="flex items-center gap-2">
              <button className="p-2 rounded-full hover:bg-white/10 text-[#146068]"><Paperclip className="w-5 h-5" /></button>
              <input type="text" placeholder="Type a message..." className={`flex-1 h-[46px] rounded-full ${theme.inputBg} border ${theme.inputBorder} px-4`} style={{ color: theme.text }} />
              <button className="p-3 rounded-full bg-[#146068] text-white"><Send className="w-5 h-5" /></button>
           </div>
        </div>
         {/* Create Offer Modal */}
         {showOfferModal && (
            <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowOfferModal(false)}>
               <div className={`w-full ${theme.cardBg} rounded-t-[30px] p-6 border-t ${theme.cardBorder} animate-slide-up`} onClick={e => e.stopPropagation()}>
                  <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mb-6" />
                  <h3 className="text-[18px] font-bold mb-4" style={{ color: theme.text }}>Create Custom Offer</h3>
                  <div className="space-y-4 mb-6">
                     <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Title</label><input type="text" value={offerForm.title} onChange={e => setOfferForm({...offerForm, title: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                     <div><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Description</label><textarea value={offerForm.description} onChange={e => setOfferForm({...offerForm, description: e.target.value})} className={`w-full h-[80px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} p-3 text-[14px] outline-none resize-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                     <div className="flex gap-3">
                        <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Price ($)</label><input type="number" value={offerForm.price} onChange={e => setOfferForm({...offerForm, price: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                        <div className="flex-1"><label className="text-[12px] font-bold mb-1.5 block" style={{ color: theme.textSecondary }}>Delivery (Days)</label><input type="number" value={offerForm.deliveryTime} onChange={e => setOfferForm({...offerForm, deliveryTime: e.target.value})} className={`w-full h-[46px] rounded-[12px] ${theme.inputBg} border ${theme.inputBorder} px-4 text-[14px] outline-none focus:border-[#146068]`} style={{ color: theme.text }} /></div>
                     </div>
                  </div>
                  <button onClick={handleSendOffer} className="w-full h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-white hover:scale-[1.02] active:scale-95 transition-all shadow-lg">Send Offer</button>
               </div>
            </div>
         )}
    </div>
  );
}