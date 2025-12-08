
import React from 'react';
import { X, Check, Upload, ChevronLeft, MapPin, Share, Heart, CheckCircle2, Star, MessageSquare, FileText, Download, User } from 'lucide-react';
import { Notification, FilterState, FreelancerProfile, ProposalFormState, Proposal } from '../types';

export const NotificationsModal = ({ theme, setShowNotifications, notifications }: { theme: any, setShowNotifications: any, notifications: Notification[] }) => (
    <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex justify-end animate-fade-in" onClick={() => setShowNotifications(false)}>
       <div className={`w-[85%] h-full ${theme.cardBg} border-l ${theme.cardBorder} backdrop-blur-2xl flex flex-col animate-slide-up`} onClick={e => e.stopPropagation()}>
          <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />
          <div className={`px-6 pt-12 pb-4 border-b ${theme.headerBorder} flex justify-between items-center relative z-10`}>
             <h2 className="text-[20px] font-bold" style={{ color: theme.text }}>Notifications</h2>
             <button onClick={() => setShowNotifications(false)} className="w-8 h-8 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10"><X className="w-5 h-5" style={{ color: theme.text }} /></button>
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
                                          <div className="w-4 h-4 rounded-full bg-white/30" />
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

export const FiltersModal = ({ theme, setShowFilters, filters, setFilters, toggleFilter }: { theme: any, setShowFilters: any, filters: FilterState, setFilters: any, toggleFilter: any }) => (
    <div className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-end animate-fade-in" onClick={() => setShowFilters(false)}>
       <div className={`w-full ${theme.cardBg} rounded-t-[30px] p-6 border-t ${theme.cardBorder} animate-slide-up flex flex-col max-h-[85vh] relative overflow-hidden`} onClick={e => e.stopPropagation()}>
           <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none z-0 mix-blend-overlay" />
           <div className="relative z-10">
               <div className="w-12 h-1.5 bg-gray-500/20 rounded-full mx-auto mb-6" />
               <div className="flex justify-between items-center mb-6">
                   <h3 className="text-[20px] font-bold" style={{ color: theme.text }}>Filters</h3>
                   <button className="text-[12px] font-bold text-[#146068]" onClick={() => setFilters({minBudget: '', maxBudget: '', deliveryTime: [], sellerLevel: [], sortBy: 'Relevance'})}>Reset All</button>
               </div>
               <div className="flex-1 overflow-y-auto space-y-6 mb-6">
                   <div>
                       <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Sort By</label>
                       <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
                           {['Relevance', 'Newest', 'Price: Low to High', 'Price: High to Low'].map(sort => (
                               <button 
                                   key={sort}
                                   onClick={() => setFilters({...filters, sortBy: sort})}
                                   className={`px-4 py-2 rounded-[12px] text-[12px] font-bold border whitespace-nowrap transition-all ${filters.sortBy === sort ? 'bg-[#146068] border-[#146068] text-white' : `${theme.inputBg} ${theme.inputBorder}`}`}
                                   style={filters.sortBy !== sort ? { color: theme.textSecondary } : {}}
                               >
                                   {sort}
                               </button>
                           ))}
                       </div>
                   </div>
                   <div>
                       <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Budget Range</label>
                       <div className="px-1 mb-4">
                           <input type="range" min="0" max="5000" value={filters.maxBudget || 1000} onChange={(e) => setFilters({...filters, maxBudget: e.target.value})} className="w-full h-2 bg-gray-500/20 rounded-lg appearance-none cursor-pointer accent-[#146068]" />
                       </div>
                       <div className="flex items-center gap-3">
                           <div className="flex-1 relative">
                               <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span>
                               <input type="number" placeholder="Min" value={filters.minBudget} onChange={e => setFilters({...filters, minBudget: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} />
                           </div>
                           <span className="opacity-50">-</span>
                           <div className="flex-1 relative">
                               <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#146068] font-bold">$</span>
                               <input type="number" placeholder="Max" value={filters.maxBudget} onChange={e => setFilters({...filters, maxBudget: e.target.value})} className={`w-full h-[50px] rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} pl-8 pr-4 outline-none focus:border-[#146068] font-bold`} style={{ color: theme.text }} />
                           </div>
                       </div>
                   </div>
                   <div>
                       <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Delivery Time</label>
                       <div className="flex flex-wrap gap-2">
                           {['Up to 24h', 'Up to 3 days', 'Up to 7 days', 'Anytime'].map(time => (
                               <button key={time} onClick={() => toggleFilter('deliveryTime', time)} className={`px-4 py-2 rounded-[12px] text-[12px] font-bold border transition-all ${filters.deliveryTime.includes(time) ? 'bg-[#146068] border-[#146068] text-white' : `${theme.inputBg} ${theme.inputBorder}`}`} style={!filters.deliveryTime.includes(time) ? { color: theme.textSecondary } : {}}>{time}</button>
                           ))}
                       </div>
                   </div>
                   <div>
                       <label className="text-[14px] font-bold mb-3 block" style={{ color: theme.text }}>Seller Level</label>
                       <div className="space-y-2">
                           {['Top Rated Seller', 'Level 2', 'Level 1', 'New Seller'].map(level => (
                               <button key={level} onClick={() => toggleFilter('sellerLevel', level)} className={`w-full flex items-center justify-between p-3 rounded-[14px] border ${filters.sellerLevel.includes(level) ? 'bg-[#146068]/10 border-[#146068] text-[#146068]' : `${theme.inputBg} ${theme.inputBorder}`}`}>
                                   <span className={`text-[13px] font-medium ${filters.sellerLevel.includes(level) ? 'text-[#146068]' : ''}`} style={{ color: !filters.sellerLevel.includes(level) ? theme.text : undefined }}>{level}</span>
                                   {filters.sellerLevel.includes(level) && <Check className="w-4 h-4" />}
                               </button>
                           ))}
                       </div>
                   </div>
               </div>
               <button onClick={() => setShowFilters(false)} className="w-full h-[54px] bg-[#146068] rounded-[16px] text-[16px] font-bold text-white shadow-xl hover:scale-[1.02] active:scale-95 transition-all">Apply Filters</button>
           </div>
       </div>
    </div>
);

export const PublicProfileModal = ({ theme, selectedUserProfile, setSelectedUserProfile }: { theme: any, selectedUserProfile: FreelancerProfile, setSelectedUserProfile: any }) => (
    <div className="absolute inset-0 z-[70] flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
       <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none mix-blend-overlay z-0" />
       <div className="h-[120px] w-full bg-gradient-to-r from-[#146068] to-[#93ccce] relative z-0">
          <button onClick={() => setSelectedUserProfile(null)} className="absolute top-8 left-4 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md flex items-center justify-center text-white active:scale-95 transition-transform"><ChevronLeft className="w-6 h-6" /></button>
       </div>
       <div className="flex-1 overflow-y-auto px-5 relative z-10 -mt-12 pb-24" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
          <div className={`${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} rounded-[24px] p-5 shadow-xl mb-6`}>
             <div className="flex justify-between items-start mb-4">
                <div className="w-[80px] h-[80px] rounded-[24px] bg-[#f3bb19] border-4 border-[#0c0c0c] flex items-center justify-center text-[28px] font-extrabold text-[#0c0c0c] -mt-10 shadow-lg relative">
                   {selectedUserProfile.initials}
                   {selectedUserProfile.online && <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#93ccce] rounded-full border-2 border-[#0c0c0c]" />}
                </div>
                <div className="flex gap-2">
                   <button className="w-10 h-10 rounded-full bg-[#146068]/10 flex items-center justify-center text-[#146068] hover:bg-[#146068]/20 transition-colors"><Share className="w-5 h-5" /></button>
                   <button className="w-10 h-10 rounded-full bg-[#f49d9d]/10 flex items-center justify-center text-[#f49d9d] hover:bg-[#f49d9d]/20 transition-colors"><Heart className="w-5 h-5" /></button>
                </div>
             </div>
             <div className="mb-4">
                <h2 className="text-[22px] font-black leading-tight mb-1" style={{ color: theme.text }}>{selectedUserProfile.name} {selectedUserProfile.verified && <span className="inline-block ml-1 align-middle"><CheckCircle2 className="w-5 h-5 text-[#93ccce]" fill="#93ccce" stroke="#0c0c0c" /></span>}</h2>
                <p className="text-[14px] font-medium" style={{ color: theme.textSecondary }}>{selectedUserProfile.title}</p>
                <div className="flex items-center gap-1 text-[12px] mt-1" style={{ color: theme.textTertiary }}><MapPin className="w-3 h-3" /> {selectedUserProfile.location}</div>
             </div>
             <div className="flex justify-between items-center p-3 rounded-[16px] bg-[#146068]/5 border border-[#146068]/10">
                <div className="text-center flex-1 border-r border-gray-500/10">
                   <div className="text-[16px] font-black text-[#146068]">{selectedUserProfile.jobSuccess}</div>
                   <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Job Success</div>
                </div>
                <div className="text-center flex-1 border-r border-gray-500/10">
                   <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.jobsCompleted}</div>
                   <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Total Jobs</div>
                </div>
                <div className="text-center flex-1">
                   <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.hourlyRate}</div>
                   <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Hourly</div>
                </div>
             </div>
          </div>
          <div className="mb-6"><h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>About</h3><p className="text-[13px] leading-relaxed" style={{ color: theme.textSecondary }}>{selectedUserProfile.bio}</p></div>
          <div className="mb-6"><h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Skills</h3><div className="flex flex-wrap gap-2">{selectedUserProfile.skills.map(skill => (<span key={skill} className={`px-3 py-1.5 rounded-lg text-[11px] font-bold border ${theme.cardBorder} bg-white/5`} style={{ color: theme.text }}>{skill}</span>))}</div></div>
          <div className="mb-6"><h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>Portfolio <span className="text-[12px] font-normal opacity-60 text-[#146068]">View All</span></h3><div className="columns-2 gap-3 space-y-3">{selectedUserProfile.portfolio.map(item => (<div key={item.id} className="break-inside-avoid rounded-[16px] overflow-hidden relative group"><div className="w-full h-auto aspect-[4/5] bg-gray-200" style={{ backgroundColor: item.image }}></div><div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent opacity-100 flex flex-col justify-end p-3"><span className="text-[12px] font-bold text-white">{item.title}</span><span className="text-[10px] text-white/70">{item.category}</span></div></div>))}</div></div>
          <div className="mb-6"><h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>Reviews <span className="text-[12px] font-normal opacity-60">Recent</span></h3><div className="space-y-3">{selectedUserProfile.reviews.map(review => (<div key={review.id} className={`p-4 rounded-[16px] ${theme.cardBg} border ${theme.cardBorder}`}><div className="flex justify-between items-start mb-2"><div className="flex items-center gap-2"><div className="w-8 h-8 rounded-full bg-[#93ccce] flex items-center justify-center text-[10px] font-black text-black">{review.clientInitials}</div><div><div className="text-[12px] font-bold" style={{ color: theme.text }}>{review.clientName}</div><div className="flex text-[10px] text-[#f3bb19]">{[...Array(5)].map((_, i) => (<Star key={i} className={`w-3 h-3 ${i < review.rating ? "fill-[#f3bb19]" : "text-gray-400"}`} />))}</div></div></div><span className="text-[10px]" style={{ color: theme.textSecondary }}>{review.date}</span></div><p className="text-[12px] italic leading-relaxed" style={{ color: theme.textSecondary }}>"{review.comment}"</p></div>))}</div></div>
       </div>
       <div className={`absolute bottom-6 left-6 right-6 h-[60px] ${theme.bottomNavBg} backdrop-blur-2xl border ${theme.bottomNavBorder} rounded-[20px] flex items-center justify-between px-2 z-20 shadow-2xl`}>
          <button className="flex-1 h-[46px] flex items-center justify-center gap-2 text-[14px] font-bold" style={{ color: theme.text }}><MessageSquare className="w-5 h-5" /> Message</button>
          <div className="w-[1px] h-[20px] bg-gray-500/20"></div>
          <button className="flex-1 h-[46px] bg-[#146068] rounded-[16px] text-white font-bold text-[14px] shadow-lg hover:scale-[1.02] active:scale-95 transition-transform mx-1">Hire Now</button>
       </div>
    </div>
);

export const ProposalSubmitModal = ({ theme, setShowProposalModal, proposalForm, setProposalForm, handleSubmitProposal, budget }: any) => (
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

export const ProposalDetailsModal = ({ theme, selectedProposal, setSelectedProposal, setSelectedUserProfile, mockFreelancerProfile }: { theme: any, selectedProposal: Proposal, setSelectedProposal: any, setSelectedUserProfile: any, mockFreelancerProfile: any }) => (
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
