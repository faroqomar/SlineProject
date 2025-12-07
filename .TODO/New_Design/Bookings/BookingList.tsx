import React from 'react';
import { Calendar } from 'lucide-react';
import { Task } from '../Common/types';

interface BookingListProps {
  tasks: Task[];
  theme: any;
  setSelectedTask: (task: Task) => void;
}

export default function BookingList({ tasks, theme, setSelectedTask }: BookingListProps) {
  return (
    <div className="space-y-3">
      {tasks?.filter(t => t.type === 'Booking').map(task => (
        <div key={task.id} onClick={() => setSelectedTask(task)} className={`${theme.cardBg} backdrop-blur-lg rounded-[18px] p-4 border ${theme.cardBorder} relative overflow-hidden cursor-pointer active:scale-[0.98]`}>
          <div className="flex items-start justify-between mb-3 relative">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-full flex items-center justify-center font-bold text-[14px] text-white" style={{ backgroundColor: task.bgColor }}>{task.author.initials}</div>
              <div>
                <div className="flex items-center gap-1">
                  <span className="text-[13px] font-bold" style={{ color: theme.text }}>{task.author.name}</span>
                  {task.author.verified && <span className="text-[12px]">✓</span>}
                </div>
                <span className="text-[10px] font-medium" style={{ color: theme.textSecondary }}>{task.author.time}</span>
              </div>
            </div>
            <div className="bg-[#146068]/20 px-2.5 py-1 rounded-lg flex items-center gap-1">
              <Calendar className="w-3 h-3 text-[#146068]" strokeWidth={2.5} />
              <span className="text-[10px] font-bold text-[#146068]">BOOKING</span>
            </div>
          </div>
          <h3 className="text-[15px] font-extrabold mb-1.5" style={{ color: theme.text }}>{task.title}</h3>
          <p className="text-[12px] mb-3 line-clamp-2" style={{ color: theme.textSecondary }}>{task.description}</p>
          <div className="flex justify-between items-center pt-3 border-t" style={{ borderColor: theme.cardBorder }}>
            <div className="flex items-center gap-3">
              <span className="text-[11px] font-bold text-[#146068]">{task.timeLeft}</span>
            </div>
            <span className="text-[15px] font-extrabold text-[#146068]">{task.budget}</span>
          </div>
        </div>
      ))}
    </div>
  );
}