#!/usr/bin/ruby
require 'json'
require 'fileutils'
require 'yaml'
require 'date'
require 'csv'

def get_generic(what,io,num) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))

  if dat.length < num
    dat = []
  else
    dat = dat.map{|k,v| v}
  end

  io.rewind
  [duration,dat]
end #}}}

def get_buttons(what,io,sol) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))
  if dat.empty?
    dat = []
  else
    dat = dat.first.last.filter{ |k,v| v }.map{|k,v| k}
  end

  dat = dat.sort.join(',')

  io.rewind
  [duration,dat,(dat==sol).to_s]
end #}}}

def get_select(what,io,sol) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))

  if dat.empty?
    dat = ''
  else
    dat = dat.first.last.to_s
  end

  io.rewind
  [duration,dat,(dat == sol).to_s]
end #}}}

def get_name(io) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'dataelements/change'
  data = find.dig('event','data')
  complex = data.dig(1,'value','time')
  complex = case complex
    when 30; 'simple'
    when 35; 'medium'
    when 40; 'complex'
  end

  io.rewind
  return [
    data.dig(1,'value','bpmn_task'),
    data.dig(1,'value','cpee_task'),
    complex
  ]
end #}}}

def get_sub(io) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'task/instantiation'

  io.rewind
  find.dig('event','data','CPEE-INSTANCE-UUID')
end #}}}

def find_solution(what,solution)
  sol = solution.find do |e|
    e.dig('task','name') == what
  end
  s0 = (sol.dig('task','element','input').to_a +  sol.dig('task','element','output').to_a).uniq.sort.join(',')
  s1 = sol.dig('task','element','input').to_a.uniq.sort.join(',')
  s2 = sol.dig('task','element','output').to_a.uniq.sort.join(',')
  s3 = (sol.dig('task','dataobject','read').to_a +  sol.dig('task','dataobject','write').to_a).uniq.sort.join(',')
  s4 = sol.dig('task','dataobject','conn').to_s

  [s0,s1,s2,s3,s4]
end

results = CSV.open('experience.csv','wb')

Dir.glob('finished/*.xes.yaml') do |f|
  io = File.open f
  yaml = YAML.load_stream io
  first = yaml.shift
  io.rewind

  if first.dig('log','trace','cpee:name') == 'Quest'
    puts 'experience: ' + File.basename(f,'.xes.yaml')

    item = get_generic( 'Experience', io, 5) rescue []

    item << get_sub(io) rescue ''
    item << get_sub(io) rescue ''
    item << get_sub(io) rescue ''

    results << item.flatten
  end
  io.close
end

results.close

solution = YAML.load_file 'solution.yaml'

results = CSV.open('results.csv','wb')
Dir.glob('finished/*.xes.yaml') do |f|
  io = File.open f
  yaml = YAML.load_stream io
  first = yaml.shift
  io.rewind

  if first.dig('log','trace','cpee:name') == 'QuestSub'
    puts 'result: ' + File.basename(f,'.xes.yaml')

    bpmn, cpee, complex = get_name io
    item1 = ['BPMN',bpmn,complex]
    item2 = ['CPEE',cpee,complex]
    item3 = [bpmn,cpee,complex]

    next if bpmn.nil? || cpee.nil?

    s0, s1, s2, s3, s4 = find_solution(bpmn,solution)
    item1 << get_buttons('BPMN Simple Questions 0', io, s0) rescue []
    item1 << get_buttons('BPMN Simple Questions 1', io, s1) rescue []
    item1 << get_buttons('BPMN Simple Questions 2', io, s2) rescue []
    item1 << get_buttons('BPMN Simple Questions 3', io, s3) rescue []
    item1 << get_select( 'BPMN Simple Questions 4', io, 'I cant be sure') rescue []

    s0, s1, s2, s3, s4 = find_solution(cpee,solution)
    item2 << get_buttons('CPEE Simple Questions 0', io, s0) rescue []
    item2 << get_buttons('CPEE Simple Questions 1', io, s1) rescue []
    item2 << get_buttons('CPEE Simple Questions 2', io, s2) rescue []
    item2 << get_buttons('CPEE Simple Questions 3', io, s3) rescue []
    item2 << get_select( 'CPEE Simple Questions 4', io, s4) rescue []

    item3 << get_generic( 'Final Questions', io, 3) rescue []

    item1 = item1.flatten
    item2 = item2.flatten

    0.upto(18){ |i| item1[i] ||= '' }
    0.upto(18){ |i| item2[i] ||= '' }

    results << [File.basename(f,'.xes.yaml')] + item1 + item2 + item3.flatten
  end
  io.close
end

results.close


