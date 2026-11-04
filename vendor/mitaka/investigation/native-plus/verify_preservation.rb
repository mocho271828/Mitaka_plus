#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'find'
require 'json'
require 'open3'
require 'time'

phase = ARGV.fetch(0, 'start')
abort 'phase must be start or final' unless %w[start final].include?(phase)
root = File.expand_path(ARGV.fetch(1))
baseline_path = File.join(root, 'investigation/native-core/baseline-manifest.json')
baseline = JSON.parse(File.read(baseline_path))
baseline_digest = Digest::SHA256.file(baseline_path).hexdigest
expected = baseline.fetch('entries').to_h { |entry| [entry.fetch('path'), entry] }
actual = {}

baseline.fetch('roots').each do |relative_root|
  Find.find(File.join(root, relative_root)) do |path|
    relative = path.delete_prefix(root + '/')
    stat = File.lstat(path)
    if stat.symlink?
      actual[relative] = { 'path' => relative, 'type' => 'symlink', 'target' => File.readlink(path) }
    elsif stat.file?
      actual[relative] = { 'path' => relative, 'type' => 'file', 'size' => stat.size,
                           'sha256' => Digest::SHA256.file(path).hexdigest }
    end
  end
end

reference = baseline.fetch('reference_repository')
reference_path = File.join(root, reference.fetch('path'))
head, head_status = Open3.capture2('git', '-C', reference_path, 'rev-parse', 'HEAD')
status, status_result = Open3.capture2('git', '-C', reference_path, 'status', '--porcelain')
abort 'reference Git inspection failed' unless head_status.success? && status_result.success?

archive = File.join(root, 'sources/official/mitaka_source_131.zip')
listing, list_status = Open3.capture2('unzip', '-Z1', archive)
abort 'official ZIP listing failed' unless list_status.success?
members = listing.lines.map(&:chomp).reject { |member| member.end_with?('/') }
zip_mismatches = []
members.each do |member|
  abort 'unexpected ZIP member path' if member.start_with?('/') || member.split('/').include?('..')
  content, read_status = Open3.capture2('unzip', '-p', archive, member)
  abort "official ZIP read failed: #{member}" unless read_status.success?
  extracted = File.join(root, 'sources/official', member)
  zip_mismatches << member unless File.file?(extracted) &&
                                 Digest::SHA256.hexdigest(content) == Digest::SHA256.file(extracted).hexdigest
end

added = (actual.keys - expected.keys).sort
removed = (expected.keys - actual.keys).sort
changed = (expected.keys & actual.keys).select { |path| expected.fetch(path) != actual.fetch(path) }.sort
regular_files = actual.values.select { |entry| entry.fetch('type') == 'file' }
start_path = File.join(root, 'investigation/repository-organization/preservation-start.json')
baseline_matches_start = phase == 'start' ||
                         JSON.parse(File.read(start_path)).fetch('baseline_sha256') == baseline_digest
report = {
  'checked_at_utc' => Time.now.utc.iso8601(6),
  'phase' => "native_plus_#{phase}",
  'baseline' => baseline_path.delete_prefix(root + '/'),
  'baseline_sha256' => baseline_digest,
  'roots' => baseline.fetch('roots'),
  'regular_file_count' => regular_files.length,
  'regular_file_bytes' => regular_files.sum { |entry| entry.fetch('size') },
  'symlink_count' => actual.length - regular_files.length,
  'added_count' => added.length, 'removed_count' => removed.length, 'changed_count' => changed.length,
  'added' => added, 'removed' => removed, 'changed' => changed,
  'reference_repository' => {
    'head' => head.strip, 'status_porcelain' => status,
    'matches_baseline_head' => head.strip == reference.fetch('head'),
    'matches_baseline_status' => status == reference.fetch('status_porcelain')
  },
  'official_zip' => {
    'extracted_files_checked' => members.length, 'mismatch_count' => zip_mismatches.length,
    'mismatches' => zip_mismatches
  },
  'baseline_matches_start' => baseline_matches_start
}
report['passed'] = added.empty? && removed.empty? && changed.empty? && zip_mismatches.empty? &&
                   report.fetch('reference_repository').fetch('matches_baseline_head') &&
                   report.fetch('reference_repository').fetch('matches_baseline_status') && baseline_matches_start
File.write(File.join(__dir__, "preservation-#{phase}.json"), JSON.pretty_generate(report) + "\n")
puts JSON.pretty_generate(report)
exit(report.fetch('passed') ? 0 : 1)
