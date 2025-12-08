import React from 'react';
import { Upload } from 'lucide-react';
import { ProposalFormState } from '../Common/types';

export default function ProposalSubmitModal({ theme, setShowProposalModal, proposalForm, setProposalForm, handleSubmitProposal, budget }: any) {
    return (
    <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowProposalModal(false)}>
       <div className={`w-full h-[90%] ${theme.cardBg} rounded-t-[30px] flex flex-col border-t ${theme.cardBorder} animate-slide-up`} onClick={e => e.stopPropagation()}>
          <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mt-3 mb-2" />
          <div className={`px-6 py-4 border-b ${theme.headerBorder}`}>
             <h2 className="text-[20px] font-bold" style={{ color: theme.text }}>Submit Proposal</h2>
          </div>
          <div className="flex-1 overflow-y-auto px-6 py-4 space-y-6">
             <div className="grid grid-cols-2 gap-4">
                <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Bid Amount</label><div className="relative"><span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span><input type="text" placeholder={budget} value={proposalForm.bidAmount} onChange={(e:any) => setProposalForm({...proposalForm, bidAmount: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} /></div></div>
                <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Delivery Time</label><input type="text" placeholder="e.g. 7 Days" value={proposalForm.deliveryTime} onChange={(e:any) => setProposalForm({...proposalForm, deliveryTime: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} px-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} /></div>
             </div>
             <div><label className="text-[12px] font-bold mb-2 block" style={{ color: theme.textSecondary }}>Cover Letter</label><textarea placeholder="Explain why you are the best fit for this job..." value={proposalForm.coverLetter} onChange={(e:any) => setProposalForm({...proposalForm, coverLetter: e.target.value})} className={`w-full h-[200px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} p-4 outline-none resize-none focus:border-[#146068] leading-relaxed`} style={{ color: theme.text }} /></div>
             <div className={`h-[100px] rounded-[14px] border-2 border-dashed ${theme.inputBorder} flex flex-col items-center justify-center gap-2 opacity-60`}><Upload className="w-6 h-6" /><span className="text-[12px] font-bold">Upload Files (Drag & Drop)</span></div>
          </div>
          <div className={`px-6 py-4 border-t ${theme.bottomNavBorder} ${theme.bottomNavBg}`}>
             <button onClick={handleSubmitProposal} className="w-full h-[54px] bg-[#146068] rounded-[16px] text-[16px] font-bold text-white shadow-xl hover:scale-[1.02] active:scale-95 transition-all">Submit Proposal</button>
          </div>
       </div>
    </div>
    );
}