import React from 'react';
import { Star, Sparkles, ArrowRight, User } from 'lucide-react';
import { Task } from '../Common/types';

interface BookingListProps {
  tasks: Task[];
  theme: any;
  setSelectedTask: (task: Task) => void;
}

export default function BookingList({ tasks, theme, setSelectedTask }: BookingListProps) {
  return (
    <div className="space-y-4">
      {tasks?.filter(t => t.type === 'Booking').map(task => (
        <div
          key={task.id}
          onClick={() => setSelectedTask(task)}
          className={`group relative overflow-hidden rounded-[24px] ${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} transition-all duration-300 cursor-pointer active:scale-[0.99] hover:-translate-y-1 hover:shadow-xl`}
        >
           {/* Color Header */}
           <div className="h-[90px] w-full relative">
               <div className="absolute inset-0 bg-gradient-to-r from-[#146068] to-[#93ccce] opacity-90" />
               <div className="absolute inset-0 bg-noise opacity-20 mix-blend-overlay" />
               <div className="absolute right-3 top-3 bg-black/20 backdrop-blur-md px-2 py-1 rounded-lg">
                   <div className="flex items-center gap-1 text-white">
                       <Sparkles className="w-3 h-3 fill-[#f3bb19] text-[#f3bb19]" />
                       <span className="text-[10px] font-bold">Featured</span>
                   </div>
               </div>
           </div>

           <div className="px-5 pb-5 relative">
               <div className="flex justify-between items-end -mt-6 mb-3">
                   <div className={`w-14 h-14 rounded-[16px] bg-[#f3bb19] border-4 flex items-center justify-center text-[18px] font-black text-[#0c0c0c] shadow-lg relative z-10`} style={{ borderColor: theme.phoneBg }}>
                       {task.author.initials}
                   </div>
                   <div className="flex items-center gap-1 mb-1 bg-[#f3bb19]/10 px-2 py-0.5 rounded-lg border border-[#f3bb19]/20">
                       <Star className="w-3 h-3 fill-[#f3bb19] text-[#f3bb19]" />
                       <span className="text-[11px] font-bold" style={{ color: theme.text }}>4.9</span>
                   </div>
               </div>

               <h3 className="text-[16px] font-extrabold leading-tight mb-1 group-hover:text-[#146068] transition-colors" style={{ color: theme.text }}>
                   {task.title}
               </h3>
               
               <div className="flex items-center gap-1.5 mb-4 text-[12px]" style={{ color: theme.textSecondary }}>
                   <User className="w-3 h-3" />
                   <span>{task.author.name}</span>
               </div>

               <div className="flex flex-wrap gap-2 mb-4">
                   {task.tags.map((tag, i) => (
                       <span key={i} className={`px-2 py-1 rounded-[6px] text-[10px] font-semibold bg-gray-500/10`} style={{ color: theme.textSecondary }}>
                           {tag}
                       </span>
                   ))}
               </div>

               <div className={`pt-3 border-t ${theme.dividerBg} flex justify-between items-center`}>
                   <div>
                       <span className="text-[10px] font-bold uppercase opacity-60 block" style={{ color: theme.textSecondary }}>From</span>
                       <span className="text-[18px] font-black text-[#146068]">{task.budget}</span>
                   </div>
                   <button className="h-[36px] px-4 rounded-full bg-[#146068] text-white text-[12px] font-bold flex items-center gap-2 group-hover:scale-105 transition-transform shadow-lg shadow-[#146068]/20">
                       Book Now <ArrowRight className="w-3 h-3" />
                   </button>
               </div>
           </div>
        </div>
      ))}
    </div>
  );
}