import React from 'react';
import { ChevronLeft, MapPin, User, FileText, Download } from 'lucide-react';
import { Proposal } from '../Common/types';

export default function ProposalDetailsModal({ theme, selectedProposal, setSelectedProposal, setSelectedUserProfile, mockFreelancerProfile }: { theme: any, selectedProposal: Proposal, setSelectedProposal: any, setSelectedUserProfile: any, mockFreelancerProfile: any }) {
    return (
    <div className="absolute inset-0 z-[60] flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
       <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none mix-blend-overlay z-0" />
       <div className={`px-4 pt-8 pb-4 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-10`}>
          <button onClick={() => setSelectedProposal(null)} className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95"><ChevronLeft className="w-6 h-6" style={{ color: theme.text }} /></button>
          <h2 className="text-[17px] font-bold" style={{ color: theme.text }}>Proposal Details</h2>
          <div className="w-10"></div>
       </div>
       <div className="flex-1 overflow-y-auto px-5 py-6 relative z-10" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
          <div className={`p-4 rounded-[20px] ${theme.cardBg} border ${theme.cardBorder} mb-6 flex items-start justify-between cursor-pointer hover:bg-white/5 active:scale-[0.98] transition-all`} onClick={() => setSelectedUserProfile(mockFreelancerProfile)}>
             <div className="flex gap-4">
                <div className="w-[60px] h-[60px] rounded-[18px] bg-[#f3bb19] flex items-center justify-center text-[20px] font-extrabold text-[#0c0c0c] border-2 border-[#f4f3f1]/20 relative">
                   {selectedProposal.freelancer.initials}
                   {selectedProposal.freelancer.online && <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-[#93ccce] rounded-full border-2 border-black" />}
                </div>
                <div>
                   <h3 className="text-[18px] font-bold leading-tight" style={{ color: theme.text }}>{selectedProposal.freelancer.name}</h3>
                   <div className="flex items-center gap-2 text-[13px] mb-1" style={{ color: theme.textSecondary }}><MapPin className="w-3.5 h-3.5" /> {selectedProposal.freelancer.location}</div>
                   <div className="flex items-center gap-2"><span className="bg-[#f3bb19]/20 text-[#f3bb19] px-2 py-0.5 rounded text-[11px] font-bold">⭐ {selectedProposal.freelancer.rating}</span>{selectedProposal.freelancer.verified && <span className="bg-[#93ccce]/20 text-[#93ccce] px-2 py-0.5 rounded text-[11px] font-bold">Verified</span>}</div>
                </div>
             </div>
             <button className="w-10 h-10 rounded-full bg-[#146068]/20 flex items-center justify-center text-[#146068]"><User className="w-5 h-5" /></button>
          </div>
          <div className="grid grid-cols-2 gap-4 mb-6">
             <div className={`p-4 rounded-[16px] bg-[#146068]/10 border border-[#146068]/20 text-center`}>
                <div className="text-[12px] font-bold mb-1" style={{ color: theme.textSecondary }}>Bid Amount</div>
                <div className="text-[22px] font-black text-[#146068]">{selectedProposal.bidAmount}</div>
             </div>
             <div className={`p-4 rounded-[16px] ${theme.cardBg} border ${theme.cardBorder} text-center`}>
                <div className="text-[12px] font-bold mb-1" style={{ color: theme.textSecondary }}>Delivery Time</div>
                <div className="text-[22px] font-black" style={{ color: theme.text }}>{selectedProposal.deliveryTime}</div>
             </div>
          </div>
          <div className="mb-8"><h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Cover Letter</h3><p className="text-[14px] leading-relaxed whitespace-pre-line p-4 rounded-[16px] border border-dashed border-gray-500/20" style={{ color: theme.textSecondary }}>{selectedProposal.coverLetter}</p></div>
          {selectedProposal.attachments.length > 0 && (
            <div className="mb-8"><h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Attachments</h3><div className="space-y-2">{selectedProposal.attachments.map((file, i) => (<div key={i} className={`flex items-center justify-between p-3 rounded-[12px] ${theme.cardBg} border ${theme.cardBorder}`}><div className="flex items-center gap-3"><div className="w-8 h-8 rounded-lg bg-[#f49d9d]/20 flex items-center justify-center text-[#f49d9d]"><FileText className="w-4 h-4" /></div><span className="text-[13px] font-medium" style={{ color: theme.text }}>{file}</span></div><button className="p-2 hover:bg-white/10 rounded-full"><Download className="w-4 h-4" style={{ color: theme.textSecondary }} /></button></div>))}</div></div>
          )}
       </div>
       <div className={`px-6 py-4 pb-6 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-10`}>
          <div className="flex gap-3"><button className="flex-1 h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-white shadow-lg shadow-[#146068]/20 hover:scale-[1.02] active:scale-95 transition-transform">Accept Offer</button><button className={`flex-1 h-[50px] rounded-[14px] text-[14px] font-bold border ${theme.cardBorder} hover:bg-white/5 active:scale-95 transition-transform`} style={{ color: theme.text }}>Decline</button></div>
       </div>
    </div>
    );
}