import React from 'react';
import { Check } from 'lucide-react';
import { FilterState } from '../Common/types';

export default function FiltersModal({ theme, setShowFilters, filters, setFilters, toggleFilter }: { theme: any, setShowFilters: any, filters: FilterState, setFilters: any, toggleFilter: any }) {
    return (
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
}