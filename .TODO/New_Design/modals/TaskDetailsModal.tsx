
import React from 'react';
import { ChevronLeft, Share, CheckCircle2, Clock, Repeat, Heart } from 'lucide-react';
import { Task, ServiceTier, FreelancerProfile, Proposal } from '../types';

interface TaskDetailsModalProps {
  selectedTask: Task;
  theme: any;
  setSelectedTask: (t: Task | null) => void;
  selectedPackageTier: ServiceTier;
  setSelectedPackageTier: (t: ServiceTier) => void;
  setSelectedUserProfile: (p: FreelancerProfile) => void;
  mockFreelancerProfile: FreelancerProfile;
  setSelectedProposal: (p: Proposal) => void;
  setShowProposalModal: (v: boolean) => void;
}

export default function TaskDetailsModal({
  selectedTask, theme, setSelectedTask, selectedPackageTier, setSelectedPackageTier,
  setSelectedUserProfile, mockFreelancerProfile, setSelectedProposal, setShowProposalModal
}: TaskDetailsModalProps) {
  
  const getSelectedPackage = () => {
    if (!selectedTask || !selectedTask.packages) return null;
    return selectedTask.packages.find(p => p.tier === selectedPackageTier);
  };
  
  const currentPackage = getSelectedPackage();

  return (
    <div 
      className="absolute inset-0 z-50 flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up"
      style={{ backgroundColor: theme.phoneBg }}
    >
      <div className={`px-4 pt-8 pb-4 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} flex items-center justify-between z-10`}>
        <button 
          onClick={() => { setSelectedTask(null); setSelectedPackageTier('Basic'); }}
          className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95"
        >
          <ChevronLeft className="w-6 h-6" style={{ color: theme.text }} />
        </button>
        <h2 className="text-[17px] font-bold" style={{ color: theme.text }}>
          {selectedTask.type === 'Booking' ? 'Booking Details' : 'Job Details'}
        </h2>
        <div className="flex gap-2">
          <button className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors active:scale-95">
            <Share className="w-5 h-5" style={{ color: theme.text }} />
          </button>
        </div>
      </div>
      
       <div className="flex-1 overflow-y-auto px-5 py-6 relative z-10" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
          <h1 className="text-[22px] font-extrabold leading-tight mb-3" style={{ color: theme.text }}>{selectedTask.title}</h1>
          
          <div 
            className="flex items-center gap-3 mb-6 cursor-pointer group"
            onClick={() => setSelectedUserProfile(mockFreelancerProfile)}
          >
              <div className="w-10 h-10 rounded-full bg-[#f3bb19] flex items-center justify-center text-[13px] font-black text-[#0c0c0c] border-2 border-[#f4f3f1]/20 relative group-active:scale-95 transition-transform">
                  {selectedTask.author.initials}
                  <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-[#93ccce] rounded-full border-2 border-[#0c0c0c]" />
              </div>
              <div>
                  <div className="flex items-center gap-1.5">
                      <h3 className="text-[14px] font-bold" style={{ color: theme.text }}>{selectedTask.author.name}</h3>
                      {selectedTask.author.verified && <CheckCircle2 className="w-3.5 h-3.5 text-[#93ccce]" fill="#93ccce" stroke="#0c0c0c" />}
                  </div>
                  <div className="text-[11px] font-medium text-[#146068]">View Profile</div>
              </div>
          </div>

          {selectedTask.type === 'Booking' && selectedTask.packages && (
            <div className="mb-6">
               <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-4`}>
                  {(['Basic', 'Standard', 'Premium'] as ServiceTier[]).map(tier => (
                     <button
                        key={tier}
                        onClick={() => setSelectedPackageTier(tier)}
                        className={`flex-1 py-2.5 rounded-[10px] text-[12px] font-bold transition-all duration-300 ${selectedPackageTier === tier ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                     >
                        {tier}
                     </button>
                  ))}
               </div>
               <div className={`p-5 rounded-[18px] ${theme.cardBg} border ${theme.cardBorder} relative overflow-hidden`}>
                  <div className="flex justify-between items-start mb-2">
                     <h3 className="text-[18px] font-black text-[#146068]">{currentPackage?.price}</h3>
                     <span className="text-[11px] font-bold bg-[#146068]/20 text-[#146068] px-2 py-1 rounded-lg uppercase tracking-wide">{currentPackage?.tier}</span>
                  </div>
                  <p className="text-[13px] leading-relaxed mb-4" style={{ color: theme.textSecondary }}>{currentPackage?.description}</p>
                  <div className="flex items-center gap-4 text-[12px] font-semibold" style={{ color: theme.text }}>
                      <div className="flex items-center gap-1.5"><Clock className="w-4 h-4 text-[#146068]" /> {currentPackage?.deliveryTime} Delivery</div>
                     <div className="flex items-center gap-1.5"><Repeat className="w-4 h-4 text-[#146068]" /> {currentPackage?.revisions} Revisions</div>
                  </div>
               </div>
            </div>
          )}

          <p className="text-[14px] leading-relaxed whitespace-pre-line mb-8" style={{ color: theme.textSecondary }}>{selectedTask.description}</p>
          
          {selectedTask.type === 'Tender' && selectedTask.proposals && (
            <div className="mb-8 animate-fade-in">
              <div className="flex items-center justify-between mb-4">
                 <h3 className="text-[16px] font-bold" style={{ color: theme.text }}>Received Proposals</h3>
                 <span className="text-[12px] font-bold bg-[#146068]/20 text-[#146068] px-2 py-1 rounded-lg">{selectedTask.proposals.length} New</span>
              </div>
              <div className="space-y-3">
                 {selectedTask.proposals.map(proposal => (
                   <div 
                     key={proposal.id}
                     onClick={() => setSelectedProposal(proposal)}
                     className={`${theme.cardBg} border ${theme.cardBorder} p-4 rounded-[16px] flex items-center justify-between cursor-pointer active:scale-[0.98] transition-all hover:bg-white/5`}
                   >
                      <div className="flex items-center gap-3">
                         <div className="w-10 h-10 rounded-full bg-[#f3bb19] flex items-center justify-center text-[12px] font-bold text-black border-2 border-white/20" onClick={(e) => { e.stopPropagation(); setSelectedUserProfile(mockFreelancerProfile); }}>
                            {proposal.freelancer.initials}
                         </div>
                         <div>
                            <div className="text-[14px] font-bold" style={{ color: theme.text }}>{proposal.freelancer.name}</div>
                            <div className="flex items-center gap-1 text-[11px]" style={{ color: theme.textSecondary }}>
                               <span>⭐ {proposal.freelancer.rating}</span>
                               <span>• {proposal.submittedAt}</span>
                            </div>
                         </div>
                      </div>
                      <div className="text-right">
                         <div className="text-[14px] font-black text-[#146068]">{proposal.bidAmount}</div>
                         <div className="text-[11px]" style={{ color: theme.textSecondary }}>{proposal.deliveryTime}</div>
                      </div>
                   </div>
                 ))}
              </div>
            </div>
          )}
       </div>

       <div className={`px-6 py-4 pb-6 ${theme.bottomNavBg} backdrop-blur-2xl border-t ${theme.bottomNavBorder} z-10`}>
        <div className="flex gap-3">
          <button 
             onClick={() => {
                if (selectedTask.type === 'Tender') {
                   setShowProposalModal(true);
                } else {
                   console.log(`Booking package: ${selectedPackageTier}`);
                }
             }}
             className={`flex-1 h-[50px] bg-[#146068] rounded-[14px] text-[14px] font-bold text-[#f4f3f1] shadow-lg shadow-[#146068]/20 hover:scale-[1.02] active:scale-95 transition-transform flex items-center justify-center gap-2`}
          >
            {selectedTask.type === 'Booking' ? (
               <>Book {selectedPackageTier} <span className="opacity-70">({currentPackage?.price})</span></>
            ) : 'Apply Now'}
          </button>
          <button className={`h-[50px] px-6 ${theme.cardBg} border ${theme.cardBorder} rounded-[14px] text-[14px] font-bold flex items-center gap-2 hover:bg-white/5 active:scale-95 transition-all`} style={{ color: theme.text }}>
            <Heart className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
