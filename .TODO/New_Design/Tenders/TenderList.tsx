import React from 'react';
import { Clock, Users, ArrowUpRight } from 'lucide-react';
import { Task } from '../Common/types';

interface TenderListProps {
  tasks: Task[];
  theme: any;
  setSelectedTask: (task: Task) => void;
}

export default function TenderList({ tasks, theme, setSelectedTask }: TenderListProps) {
  return (
    <div className="space-y-4">
      {tasks?.filter(t => t.type === 'Tender').map(task => (
        <div
            key={task.id}
            onClick={() => setSelectedTask(task)}
            className={`group relative overflow-hidden rounded-[20px] ${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} hover:border-[#f49d9d]/40 transition-all duration-300 cursor-pointer active:scale-[0.99]`}
        >
            {/* Left Accent */}
            <div className="absolute left-0 top-0 bottom-0 w-[4px] bg-[#f49d9d] opacity-80" />
            
            <div className="p-4 pl-6">
                <div className="flex justify-between items-start mb-2">
                   <div className="flex gap-2 mb-1">
                      {task.tags.slice(0, 2).map((tag, i) => (
                          <span key={i} className={`px-2 py-0.5 rounded-[6px] text-[10px] font-bold uppercase tracking-wide border ${theme.tagBorder} ${theme.tagBg}`} style={{ color: theme.textSecondary }}>
                             {tag}
                          </span>
                      ))}
                   </div>
                   <span className="text-[11px] font-medium" style={{ color: theme.textSecondary }}>{task.author.time}</span>
                </div>

                <h3 className="text-[16px] font-bold leading-snug mb-2 pr-4 group-hover:text-[#f49d9d] transition-colors" style={{ color: theme.text }}>
                    {task.title}
                </h3>
                
                <p className="text-[13px] leading-relaxed line-clamp-2 mb-4 opacity-80" style={{ color: theme.textSecondary }}>
                    {task.description}
                </p>

                <div className={`pt-3 border-t ${theme.dividerBg} flex justify-between items-center`}>
                    <div className="flex items-center gap-4">
                        <div className="flex items-center gap-1.5" style={{ color: theme.textSecondary }}>
                            <Clock className="w-3.5 h-3.5" />
                            <span className="text-[11px] font-bold">{task.timeLeft}</span>
                        </div>
                        <div className="flex items-center gap-1.5" style={{ color: theme.textSecondary }}>
                            <Users className="w-3.5 h-3.5" />
                            <span className="text-[11px] font-bold">{task.offers || 0} bids</span>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 text-[#f49d9d]">
                        <span className="text-[15px] font-black">{task.budget}</span>
                        <ArrowUpRight className="w-4 h-4" />
                    </div>
                </div>
            </div>
        </div>
      ))}
    </div>
  );
}