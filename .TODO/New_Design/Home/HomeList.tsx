import React from 'react';
import { Task } from '../Common/types';
import { Clock, Users, ArrowRight, Sparkles, MapPin, Star } from 'lucide-react';

interface HomeListProps {
  tasks: Task[];
  theme: any;
  setSelectedTask: (task: Task) => void;
}

export default function HomeList({ tasks, theme, setSelectedTask }: HomeListProps) {
  
  const renderTenderCard = (task: Task) => (
    <div
      key={task.id}
      onClick={() => setSelectedTask(task)}
      className={`group relative overflow-hidden rounded-[24px] ${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} hover:border-[#f49d9d]/50 transition-all duration-300 cursor-pointer active:scale-[0.99]`}
    >
      {/* Accent Bar */}
      <div className="absolute left-0 top-0 bottom-0 w-[6px] bg-[#f49d9d] z-10" />
      
      <div className="p-5 pl-7">
        {/* Header: User & Meta */}
        <div className="flex justify-between items-start mb-3">
           <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#f49d9d]/10 flex items-center justify-center text-[13px] font-black text-[#f49d9d] border border-[#f49d9d]/20">
                 {task.author.initials}
              </div>
              <div>
                 <div className="flex items-center gap-2">
                    <span className="text-[13px] font-bold" style={{ color: theme.text }}>{task.author.name}</span>
                    <span className="text-[10px] opacity-60 font-medium" style={{ color: theme.textSecondary }}>• {task.author.time}</span>
                 </div>
                 <div className="flex items-center gap-1 text-[#f49d9d]">
                    <span className="text-[10px] font-black tracking-wide uppercase">Job Request</span>
                 </div>
              </div>
           </div>
           {task.isHot && (
              <div className="px-2.5 py-1 rounded-full bg-[#f49d9d] flex items-center gap-1 shadow-lg shadow-[#f49d9d]/20">
                 <span className="text-[10px] font-black text-white uppercase tracking-wider">Hot</span>
              </div>
           )}
        </div>

        {/* Content */}
        <div className="mb-4">
           <h3 className="text-[17px] font-extrabold leading-tight mb-2 group-hover:text-[#f49d9d] transition-colors" style={{ color: theme.text }}>{task.title}</h3>
           <p className="text-[13px] leading-relaxed line-clamp-2" style={{ color: theme.textSecondary }}>{task.description}</p>
        </div>

        {/* Tags */}
        <div className="flex flex-wrap gap-2 mb-4">
           {task.tags.slice(0, 3).map((tag, i) => (
              <span key={i} className={`px-2.5 py-1 rounded-[8px] text-[11px] font-semibold border ${theme.tagBorder} ${theme.tagBg}`} style={{ color: theme.textSecondary }}>
                 {tag}
              </span>
           ))}
        </div>

        {/* Footer: Stats & Budget */}
        <div className={`pt-4 border-t ${theme.dividerBg} flex justify-between items-center`}>
           <div className="flex items-center gap-4">
              <div className="flex items-center gap-1.5" style={{ color: theme.textSecondary }}>
                 <Clock className="w-3.5 h-3.5" />
                 <span className="text-[12px] font-semibold">{task.timeLeft}</span>
              </div>
              <div className="flex items-center gap-1.5" style={{ color: theme.textSecondary }}>
                 <Users className="w-3.5 h-3.5" />
                 <span className="text-[12px] font-semibold">{task.offers || 0} proposals</span>
              </div>
           </div>
           <div className="flex items-center gap-2">
              <span className="text-[10px] uppercase font-bold opacity-60" style={{ color: theme.text }}>Budget</span>
              <span className="text-[18px] font-black tracking-tight" style={{ color: theme.text }}>{task.budget}</span>
           </div>
        </div>
      </div>
    </div>
  );

  const renderBookingCard = (task: Task) => (
    <div
      key={task.id}
      onClick={() => setSelectedTask(task)}
      className={`group relative overflow-hidden rounded-[24px] ${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} hover:border-[#146068]/50 transition-all duration-300 cursor-pointer active:scale-[0.99]`}
    >
      {/* Visual Header */}
      <div className="h-[110px] w-full relative overflow-hidden">
         <div className="absolute inset-0 bg-gradient-to-r from-[#146068] to-[#93ccce] opacity-90" />
         <div className="absolute inset-0 bg-noise opacity-20 mix-blend-overlay" />
         {/* Decorative Circles */}
         <div className="absolute -right-4 -top-4 w-24 h-24 rounded-full bg-white/10 blur-2xl" />
         <div className="absolute left-10 bottom-0 w-32 h-32 rounded-full bg-black/10 blur-3xl" />
         
         <div className="absolute top-4 right-4 bg-black/20 backdrop-blur-md px-2.5 py-1 rounded-lg border border-white/10">
            <div className="flex items-center gap-1 text-white">
               <Sparkles className="w-3 h-3 text-[#f3bb19] fill-[#f3bb19]" />
               <span className="text-[10px] font-bold uppercase tracking-wide">Service</span>
            </div>
         </div>
      </div>

      <div className="px-5 pb-5 relative">
         {/* Avatar overlapping header */}
         <div className="flex justify-between items-end -mt-8 mb-3">
             <div className={`w-16 h-16 rounded-[18px] bg-[#f3bb19] border-4 ${theme.headerBorder} flex items-center justify-center text-[20px] font-black text-[#0c0c0c] shadow-lg relative z-10`} style={{ borderColor: theme.phoneBg }}>
                {task.author.initials}
                {task.author.verified && <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#93ccce] rounded-full border-2 border-white flex items-center justify-center"><span className="text-[8px]">✓</span></div>}
             </div>
             <div className="flex items-center gap-1 mb-1">
                 <Star className="w-3.5 h-3.5 fill-[#f3bb19] text-[#f3bb19]" />
                 <span className="text-[12px] font-bold" style={{ color: theme.text }}>4.9</span>
                 <span className="text-[11px] opacity-60" style={{ color: theme.textSecondary }}>(128)</span>
             </div>
         </div>

         <div className="mb-4">
            <h3 className="text-[16px] font-extrabold leading-tight mb-1 group-hover:text-[#146068] transition-colors" style={{ color: theme.text }}>{task.title}</h3>
            <p className="text-[12px] opacity-70" style={{ color: theme.textSecondary }}>by {task.author.name}</p>
         </div>

         <div className="flex items-end justify-between">
            <div>
               <p className="text-[10px] font-bold uppercase opacity-60 mb-0.5" style={{ color: theme.textSecondary }}>Starting at</p>
               <div className="text-[20px] font-black text-[#146068] tracking-tight">{task.budget}</div>
            </div>
            <button className={`w-10 h-10 rounded-full ${theme.inputBg} border ${theme.cardBorder} flex items-center justify-center group-hover:bg-[#146068] group-hover:text-white transition-all`}>
               <ArrowRight className="w-5 h-5" style={{ color: theme.textSecondary }} />
            </button>
         </div>
      </div>
    </div>
  );

  return (
    <div className="space-y-5 pb-4">
      {tasks?.map((task) => (
        <React.Fragment key={task.id}>
           {task.type === 'Tender' ? renderTenderCard(task) : renderBookingCard(task)}
        </React.Fragment>
      ))}
    </div>
  );
}