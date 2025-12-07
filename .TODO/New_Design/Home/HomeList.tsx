import React from 'react';
import { Task } from '../Common/types';

interface HomeListProps {
  tasks: Task[];
  theme: any;
  setSelectedTask: (task: Task) => void;
}

export default function HomeList({ tasks, theme, setSelectedTask }: HomeListProps) {
  return (
    <div className="space-y-4 pb-4">
      {tasks?.map((task) => (
        <div
          key={task.id}
          className={`${theme.cardBg} backdrop-blur-2xl rounded-[20px] overflow-hidden border ${theme.cardBorder} hover:${theme.cardBorderHover} hover:-translate-y-2 hover:scale-[1.02] active:scale-[0.98] transition-all duration-500 cursor-pointer`}
          onClick={() => setSelectedTask(task)}
        >
          <div className="h-32 relative" style={{ backgroundColor: task.bgColor }}>
            <div className={`absolute inset-0 bg-gradient-to-t ${theme.taskGradient} to-transparent`} />
            {task.isHot && <div className="absolute top-3 left-3 bg-[#f49d9d] text-[#f4f3f1] px-2.5 py-1 rounded-lg text-[10px] font-extrabold uppercase tracking-wide shadow-lg">🔥 HOT</div>}
            <div className="absolute top-3 right-3"><span className={`px-3 py-1.5 rounded-lg text-[10px] font-extrabold uppercase tracking-wider backdrop-blur-lg border shadow-lg ${task.type === "Tender" ? "bg-[#f49d9d]/90 text-[#f4f3f1] border-[#f4f3f1]/30" : "bg-[#146068]/90 text-[#f4f3f1] border-[#93ccce]/30"}`}>{task.type}</span></div>
          </div>
          <div className="p-4 relative">
            <h3 className="text-[16px] font-extrabold mb-2" style={{ color: theme.text }}>{task.title}</h3>
            <p className="text-[13px] leading-relaxed mb-3" style={{ color: theme.textSecondary }}>{task.description}</p>
            <div className={`flex justify-between items-center pt-3 border-t ${theme.cardBorder}`}>
              <span className="text-[18px] font-black text-[#146068]">{task.budget}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}